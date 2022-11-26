local M = {}

local util = require'buffls/util'

---@class BufflsTsQueryHandlerContext
---@field params table
---@field tstree userdata
---@field nodes {[string]: userdata}
---@field metadata table
local BufflsTsQueryHandlerContext = {}

---@private
BufflsTsQueryHandlerContext.__index = BufflsTsQueryHandlerContext

---@param node userdata|string The TreeSitter node to resolve, or the name of that match in self.nodes
---@return string?
function BufflsTsQueryHandlerContext:text(node)
    if type(node) == 'string' then
        node = self.nodes[node]
    end
    return vim.treesitter.get_node_text(node, self.params.bufnr)
end

local function node_range(node)
    local sr, sc, er, ec = node:range()
    return sr + 1, sc + 1, er + 1, ec + 1
end

---@param node userdata|string The TreeSitter node to resolve, or the name of that match in self.nodes
---@return boolean
function BufflsTsQueryHandlerContext:is_node_in_range(node)
    if type(node) == 'string' then
        node = self.nodes[node]
    end
    local range = self.params.range or {
        row = self.params.row,
        col = self.params.col,
        end_row = self.params.row,
        end_col = self.params.col,
    }
    local sr, sc, er, ec = node_range(node)
    if range.end_row < sr then
        return false
    end
    if range.end_row == sr and range.end_col < sc then
        return false
    end
    if er < range.row then
        return false
    end
    if er == range.row and ec <= range.col then
        return false
    end
    return true
end

function BufflsTsQueryHandlerContext:is_after_node(node)
    if type(node) == 'string' then
        node = self.nodes[node]
    end
    local _, _, sr, sc = node_range(node)
    if range.end_row < sr then
        return false
    end
    if range.end_row == sr and range.end_col < sc then
        return false
    end
    if er < range.row then
        return false
    end
    if er == range.row and ec <= range.col then
        return false
    end
end

---@class BufflsTsQueryRouter
---@field language string
---@field private direct_generators function[]
---@field private ts_query_generators function[]
M.BufflsTsQueryRouter = {}
M.BufflsTsQueryRouter.__index = M.BufflsTsQueryRouter

---@return BufflsTsQueryRouter
function M.BufflsTsQueryRouter:new(language)
    return setmetatable({
        language = language,
        direct_generators = {},
        ts_query_generators = {},
    }, self)
end

---@param generator fun(ctx: BufflsTsQueryHandlerContext): table[]?
function M.BufflsTsQueryRouter:add_direct_generator(generator)
    table.insert(self.direct_generators, generator)
end

---@param query string
---@param generator fun(ctx: BufflsTsQueryHandlerContext): table[]?
function M.BufflsTsQueryRouter:add_ts_generator(query, generator)
    vim.treesitter.parse_query(self.language, query)
    table.insert(self.ts_query_generators, {
        query = query,
        generator = generator,
    })
end

local whitespace_pattern = vim.regex[[^\s*$]]

function M.BufflsTsQueryRouter:call_all(params, parser)
    local results = {}
    local results_len = 0

    for _, generator in ipairs(self.direct_generators) do
        util.resilient(function()
            local handler_result = generator(params)
            if handler_result then
                for _, item in ipairs(handler_result) do
                    results_len = results_len + 1
                    results[results_len] = item
                end
            end
        end)
    end

    local range = params.range or {
        row = params.row,
        col = params.col,
        end_row = params.row,
        end_col = params.col,
    }
    local function is_node_in_range(node)
        local sr, sc, er, ec = node:range()
        sr = sr + 1
        sc = sc + 1
        er = er + 1
        ec = ec + 1
        if range.end_row < sr then
            return false
        end
        if range.end_row == sr and range.end_col < sc then
            return false
        end
        if er < range.row then
            return false
        end
        if er == range.row and ec < range.col then
            return false
        end
        return true
    end
    local parsed = parser:parse()
    local tstree = unpack(parsed)
    local queries = vim.tbl_map(function(generator)
        return '[' .. generator.query .. ']'
    end, self.ts_query_generators)
    local combined_query = vim.treesitter.query.parse_query(self.language, table.concat(queries))

    for query_idx, captures_array, metadata in combined_query:iter_matches(tstree:root(), params.bufnr) do
        local captures_dict = {}
        for capture_idx, capture_value in pairs(captures_array) do
            captures_dict[combined_query.captures[capture_idx]] = capture_value
        end
        local ctx = setmetatable({
            params = params,
            tstree = tstree,
            nodes = captures_dict,
            metadata = metadata,
        }, BufflsTsQueryHandlerContext)

        local function should_visit()
            if captures_dict.HERE then
                return ctx:is_node_in_range('HERE')
            elseif captures_dict.AFTER_HERE then
                local _, _, ner, nec = captures_dict.AFTER_HERE:range()
                nec = nec + 1
                local r = params.row - 1
                local c = params.col

                if r < ner then
                    return false
                end
                if r == ner and c < nec then
                    return false
                end
                local text_to_here = table.concat(vim.api.nvim_buf_get_text(params.bufnr, ner, nec, r, c, {}))
                if whitespace_pattern:match_str(text_to_here) then
                    return true
                end

                local node_after = captures_dict.AFTER_HERE:next_sibling()
                if node_after then
                    return ctx:is_node_in_range(node_after)
                end
            else
                return true
            end
        end

        if should_visit() then
            local generator = self.ts_query_generators[query_idx].generator
            util.resilient(function()
                local handler_result = generator(ctx)
                if handler_result then
                    for _, item in ipairs(handler_result) do
                        results_len = results_len + 1
                        results[results_len] = item
                    end
                end
            end)
        end
    end
    if 0 < results_len then
        return results
    end
end

function M.BufflsTsQueryRouter:__call(ls, params)
    if params == nil then
        params = ls
    end
    local parser = vim.treesitter.get_parser(params.buf, self.language)
    return self:call_all(params, parser)
end

---@class BufflsTsLs
---@field language string
---@field actions BufflsTsQueryRouter
---@field diagnostics BufflsTsQueryRouter
---@field formatting BufflsTsQueryRouter
---@field hover BufflsTsQueryRouter
---@field completion BufflsTsQueryRouter
M.BufflsTsLs = {}
M.BufflsTsLs.__index = M.BufflsTsLs

function M.BufflsTsLs:new(language)
    return setmetatable({
        language = language,
        actions = M.BufflsTsQueryRouter:new(language),
        diagnostics = M.BufflsTsQueryRouter:new(language),
        formatting = M.BufflsTsQueryRouter:new(language),
        hover = M.BufflsTsQueryRouter:new(language),
        completion = M.BufflsTsQueryRouter:new(language),
    }, self)
end

---@param bufnr? integer
---@return BufflsTsLs
function M.BufflsTsLs:for_buffer(bufnr)
    bufnr = bufnr or 0
    if self.__index == self then
        local language = vim.api.nvim_buf_get_option(bufnr, 'filetype')
        if language == "" then
            error(table.concat({
                'Cannot use BufflsTsLs:for_buffer() on typeless buffer.',
                'Either set a filetype for the buffer or use BufflsTsLs:new("language"):for_buffer().',
            }, ' '), 2)
        end
        self = self:new(language)
    end
    vim.api.nvim_buf_set_var(bufnr, 'buffls', function() return self end)
    return self
end

---@param title string
---@param action function
function M.BufflsTsLs:add_action(title, action)
    self.actions:add_direct_generator(function(params)
        return {{
            title = title,
            action = function()
                action(params)
            end,
        }}
    end)
end

---@param generator fun(ctx: BufflsTsQueryHandlerContext): table[]?
function M.BufflsTsLs:add_completions_direct_generator(generator)
    self.completion:add_direct_generator(function(params)
        local result = generator(params)
        if result then
            return {{items = result}}
        else
            return {}
        end
    end)
end

---@param query string
---@param generator fun(ctx: BufflsTsQueryHandlerContext): table[]?
function M.BufflsTsLs:add_completions_ts_generator(query, generator)
    self.completion:add_ts_generator(query, function(ctx)
        local result = generator(ctx)
        if result then
            return {{items = result}}
        else
            return {}
        end
    end)
end

return M
