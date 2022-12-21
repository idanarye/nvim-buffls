---@mod BufflsTsLs BuffLS based on TreeSitter queries

local BufflsTsQueryRouter = require'buffls.TsQueryRouter'

---A BuffLS that uses TreeSitter queries. It has |BufflsTsQueryRouter| fields
---for adding handlers directly, which must return their output in null-ls'
---format. It also provides helper methods for when that structure is too
---complicated for basic usage (e.g. - for code actions just giving a name and
---function is often enough for most of BuffLS' use cases)
---@class BufflsTsLs
---@field language string the language for TS queries
---@field actions BufflsTsQueryRouter handles LSP code actions
---@field diagnostics BufflsTsQueryRouter handles LSP diagnostics
---@field formatting BufflsTsQueryRouter handles LSP formatting
---@field hover BufflsTsQueryRouter handles LSP hover (sig&doc preview)
---@field completion BufflsTsQueryRouter handles LSP completion
local BufflsTsLs = {}
BufflsTsLs.__index = BufflsTsLs

---Create a BuffLS without a buffer. The specified language must be
---installed (see |:TSInstall|). |BufflsTsLs:for_buffer| is usually preferred.
---@param language string the language for TS queries
---@return BufflsTsLs
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

---Assign a BuffLS to a buffer. Can be called on an existing BuffLS, or on the
---class itself to create a new langauge server and immediately attach it to a
---buffer. In the latter case, the BuffLS will use the 'filetype' of the buffer
---as its `langauge`.
---@param bufnr? integer the buffer number. Leave empty for current buffer.
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

---@param title string the text to display to the use when choosing actions
---@param action function the action itself
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
---Register a function that generates a list of code completions.
---
---Unlike null-ls' format, here the generator does not need to put the
---completions under an `items` field.
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
---Register a function that generates a list of code completions only when the
---cursor position matches the TreeSitter query.
---
---Unlike null-ls' format, here the generator does not need to put the
---completions under an `items` field.
---
---Refer to |BufflsTsQueryRouter:add_ts_generator| to learn how TreeSitter
---queries interface with `BufflsTsLs` generators.
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
