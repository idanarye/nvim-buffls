---@mod BufflsTsLs BuffLS based on TreeSitter queries

local BufflsTsQueryRouter = require'buffls.TsQueryRouter'

---@class BufflsTsLs
---@field language string
---@field actions BufflsTsQueryRouter
---@field diagnostics BufflsTsQueryRouter
---@field formatting BufflsTsQueryRouter
---@field hover BufflsTsQueryRouter
---@field completion BufflsTsQueryRouter
local BufflsTsLs = {}
BufflsTsLs.__index = BufflsTsLs

function BufflsTsLs:new(language)
    return setmetatable({
        language = language,
        actions = BufflsTsQueryRouter:new(language),
        diagnostics = BufflsTsQueryRouter:new(language),
        formatting = BufflsTsQueryRouter:new(language),
        hover = BufflsTsQueryRouter:new(language),
        completion = BufflsTsQueryRouter:new(language),
    }, self)
end

---@param bufnr? integer
---@return BufflsTsLs
function BufflsTsLs:for_buffer(bufnr)
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
function BufflsTsLs:add_action(title, action)
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
function BufflsTsLs:add_completions_direct_generator(generator)
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
function BufflsTsLs:add_completions_ts_generator(query, generator)
    self.completion:add_ts_generator(query, function(ctx)
        local result = generator(ctx)
        if result then
            return {{items = result}}
        else
            return {}
        end
    end)
end

return BufflsTsLs
