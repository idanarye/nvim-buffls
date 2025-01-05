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

---@param title string the text to display to the use when choosing actions
---@param action function the action itself
function BufflsLineListLs:add_action(title, action)
    self.actions:add_direct_generator(function(params)
        return {{
            title = title,
            action = function()
                action(params)
            end,
        }}
    end)
end

---@param title string the text to display to the use when choosing actions
---@param gen_new_lines fun(params): string[]
function BufflsLineListLs:add_insertion_action(title, gen_new_lines)
    self:add_action(title, function(params)
        local new_lines = gen_new_lines(params)
        if new_lines ~= nil and next(new_lines) ~= nil then
            local current_lines = vim.api.nvim_buf_get_lines(params.bufnr, 0, -1, true)
            local replacement_start = #current_lines
            local replacement_end = replacement_start
            while current_lines[replacement_start] == '' do
                replacement_start = replacement_start - 1
            end
            vim.api.nvim_buf_set_lines(params.bufnr, replacement_start, replacement_end, true, new_lines)
        end
    end)
end

return BufflsLineListLs
