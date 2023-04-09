---@mod buffls.TsQueryRouter TS-based router for specific LSP request type

local util = require'buffls.util'

local BufflsTsQueryHandlerContext = require'buffls.TsQueryHandlerContext'

---Responsible for a single type of LSP request that a |BufflsTsLs| handles.
---For each such request, it'll run all the generators registered on it can
---concatenate their results.
---@class BufflsTsQueryRouter
---@field language string the language for TS queries
---@field private direct_generators function[]
---@field private ts_query_generators function[]
local BufflsTsQueryRouter = {}
BufflsTsQueryRouter.__index = BufflsTsQueryRouter

---@private
---@return BufflsTsQueryRouter
function BufflsTsQueryRouter:new(language)
    return setmetatable({
        language = language,
        direct_generators = {},
        ts_query_generators = {},
    }, self)
end

---Register a function that receives the parameters object from null-ls and
---returns a result in null-ls' format. This means that it needs to return a
---list of results.
---@param generator function
function BufflsTsQueryRouter:add_direct_generator(generator)
    table.insert(self.direct_generators, generator)
end

---Register a |BufflsTsGenerator| that runs only when the specified query
---matches the cursor's position.
---
---A query matches the cursor position if one of these two things happen:
--- - The cursor is on a node that the query captures using `@HERE`.
--- - The cursor is after a node that the query captures using `@AFTER_HERE`.
---@param query string a TreeSitter query
---@param generator BufflsTsGenerator
function BufflsTsQueryRouter:add_ts_generator(query, generator)
    vim.treesitter.query.parse(self.language, query)
    table.insert(self.ts_query_generators, {
        query = query,
        generator = generator,
    })
end

---A function that receives a |BufflsTsQueryHandlerContext| and responds to a
---particualr LSP request type using null-ls format. This means that it needs
---to return a list of results.
---@alias BufflsTsGenerator fun(ctx: BufflsTsQueryHandlerContext): table[]?

local whitespace_pattern = vim.regex[[^\s*$]]

---@private
function BufflsTsQueryRouter:call_all(params, parser)
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

    local range = util.normalize_range(params)
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
    local combined_query = vim.treesitter.query.parse(self.language, table.concat(queries))

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
            end
            if captures_dict.AFTER_HERE then
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

---@private
function BufflsTsQueryRouter:__call(ls, params)
    if params == nil then
        params = ls
    end
    local parser = vim.treesitter.get_parser(params.buf, self.language)
    return self:call_all(params, parser)
end

return BufflsTsQueryRouter
