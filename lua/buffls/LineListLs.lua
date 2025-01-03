---@mod buffls.LineListLs BuffLS for a simple text buffer where each line is a string entry

local BufflsQueryRouter = require'buffls.QueryRouter'

---@class BufflsLineListLs
---@field gen_entries fun(): table<string, any>
local BufflsLineListLs = {}
BufflsLineListLs.__index = BufflsLineListLs

local function init_for_gen_entries(ls)
    ls.completion:add_direct_generator(function()
        return {{
            items = vim.iter(pairs(ls.gen_entries())):map(function(name)
                return {label = name}
            end):totable()
        }}
    end)
end

---Create a BuffLS without a buffer. |BufflsLineListLs:for_buffer| is usually
---preferred.
---@param gen_entries fun(): table<string, any>
---@return BufflsLineListLs
function BufflsLineListLs:new(gen_entries)
    local this = setmetatable({
        gen_entries = gen_entries,
        actions = BufflsQueryRouter:new(),
        diagnostics = BufflsQueryRouter:new(),
        formatting = BufflsQueryRouter:new(),
        hover = BufflsQueryRouter:new(),
        completion = BufflsQueryRouter:new(),
    }, self)
    init_for_gen_entries(this)
    return this
end

---Assign a BuffLS to a buffer. Must be called on an existing BuffLS
---@param bufnr? integer the buffer number. Leave empty for current buffer.
---@return BufflsLineListLs
function BufflsLineListLs:for_buffer(bufnr)
    assert(self.__index ~= self)
    bufnr = bufnr or 0
    if vim.api.nvim_get_option_value('filetype', {buf = bufnr}) == '' then
        vim.api.nvim_set_option_value('filetype', 'text', {buf = bufnr})
    end
    vim.api.nvim_buf_set_var(bufnr, 'buffls', function() return self end)
    return self
end

return BufflsLineListLs
