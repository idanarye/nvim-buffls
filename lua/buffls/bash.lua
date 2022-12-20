---@class BufflsForBash
---@field package flags table
local BufflsForBash = {}

---@private
BufflsForBash.__index = BufflsForBash

---@param flag string|string[]
---@param args? (string|table)[]|function
function BufflsForBash:add_flag(flag, args)
    if type(flag) == 'string' then
        flag = {flag}
    end

    local flag_value
    if args == nil then
        flag_value = false
    elseif vim.is_callable(args) then
        flag_value = args
    elseif vim.tbl_islist(args) then
        flag_value = function()
            return args
        end
    else
        error('Illegal value for `args`')
    end

    for _, flag_name in ipairs(flag) do
        self.flags[flag_name] = flag_value
    end
end

local bash_word_query = vim.treesitter.parse_query('bash', '(word) @_')

local function find_real_word_for_completion(ctx)
    for _, node in bash_word_query:iter_captures(ctx.tstree:root(), ctx.params.bufnr) do
        if ctx:is_node_in_range(node) then
            local sr, sc = node:range()
            return table.concat(vim.api.nvim_buf_get_text(ctx.params.bufnr, sr, sc, ctx.params.row - 1, ctx.params.col, {}), '\n')
        end
    end
    return ''
end

---@param ls BufflsTsLs
---@return BufflsForBash
return function(ls)
    local bash_wrapper = setmetatable({
        flags = {}
    }, BufflsForBash)

    ls:add_completions_ts_generator('((word) @flag (#match? @flag "^-")) @HERE', function(ctx)
        local result = {}
        local real_word = find_real_word_for_completion(ctx)
        for flag in pairs(bash_wrapper.flags) do
            if vim.startswith(flag, real_word) then
                table.insert(result, {label=flag})
            end
        end
        return result
    end)
    ls:add_completions_ts_generator('((word) @flag (#match? @flag "^-")) @AFTER_HERE', function(ctx)
        local flag_args = bash_wrapper.flags[ctx:text('flag')]
        if not flag_args then
            return
        end
        local real_word = find_real_word_for_completion(ctx)
        local possible_args = flag_args(real_word)
        if not possible_args then
            return
        end
        local result = {}
        for _, item in ipairs(possible_args) do
            if type(item) == 'string' then
                if vim.startswith(item, real_word) then
                    table.insert(result, {label=item})
                end
            else
                if vim.startswith(item.label, real_word) then
                    table.insert(result, item)
                end
            end
        end
        return result
    end)

    return bash_wrapper
end
