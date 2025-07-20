---@mod buffls.ForBash BuffLS for Bash buffer

local util = require'buffls.util'

local BufflsTsLs = require'buffls.TsLs'

---An extension to |BufflsTsLs| for working with with Bash buffers.
---
---Create and register instances of with `for_buffer` like you would a
---|BufflsTsLs|.
---@class BufflsForBash: BufflsTsLs
---@field package arg_completers (fun(ctx: table): table)[]
---@field package flags table
local BufflsForBash = setmetatable({}, {__index = BufflsTsLs})

---@private
BufflsForBash.__index = BufflsForBash

---@param completer fun(ctx: table): table?
function BufflsForBash:add_cli_arg(completer)
    table.insert(self.arg_completers, completer)
end

---Add completion for a flag.
---
---The flag name(s) must be given together with the preceding `-` or `--`. The
---argument can be:
---- Omitted for argumentless flags.
---- A list of possible flags.
---- A function that returns a list of possible flags.
---For the list/function, each flag must either be a string or an LSP
---completion item.
---@param flag string|string[] the name of the flag. Table for multiple names
---@param args? (string|table)[]|function the options for flag arguments
function BufflsForBash:add_flag(flag, args)
    if type(flag) == 'string' then
        flag = {flag}
    end

    local flag_value
    if args == nil then
        flag_value = false
    elseif vim.is_callable(args) then
        flag_value = args
    elseif vim.islist(args) then
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

local bash_word_query = vim.treesitter.query.parse('bash', '(word) @_')

local function find_range_of_real_word_for_completion(ctx)
    for _, node in bash_word_query:iter_captures(ctx.tstree:root(), ctx.params.bufnr) do
        if ctx:is_node_in_range(node) then
            local sr, sc = node:range()
            return sr, sc
        end
    end
    return nil
end

local function find_real_word_for_completion(ctx)
    local sr, sc = find_range_of_real_word_for_completion(ctx)
    if sr then
        return table.concat(vim.api.nvim_buf_get_text(ctx.params.bufnr, sr, sc, ctx.params.row - 1, ctx.params.col, {}), '\n')
    else
        return ''
    end
end

local function normalize_completion(completion)
    if type(completion) == 'string' then
        return {label = completion}
    else
        return completion
    end
end

---@param bufnr? integer the buffer number. Leave empty for current buffer.
---@return BufflsForBash
function BufflsForBash:for_buffer(bufnr)
    bufnr = bufnr or 0
    if vim.api.nvim_get_option_value('filetype', {buf = bufnr}) == '' then
        vim.api.nvim_set_option_value('filetype', 'bash', {buf = bufnr})
    end
    if self.__index == self then
        self = self:new()
    end
    vim.api.nvim_buf_set_var(bufnr, 'buffls', function() return self end)
    return self
end

---@return BufflsForBash
function BufflsForBash:new()
    local ls = setmetatable(BufflsTsLs:new('bash'), self)
    ls.arg_completers = {}
    ls.flags = {}

    ls:add_completions_direct_generator(function(ctx)
        local range = util.normalize_range(ctx.params)
        local previous_args = {}
        local relevant_arg
        for _, node in bash_word_query:iter_captures(ctx.tstree:root(), ctx.params.bufnr) do
            local sr, sc, er, ec = node:range()
            sr = sr + 1
            sc = sc + 1
            er = er + 1
            ec = ec + 1

            if range.end_row < sr then
                break
            end
            if range.end_row == sr then
                if range.end_col < sc then
                    break
                elseif range.col < ec then
                    relevant_arg = table.concat(vim.api.nvim_buf_get_text(ctx.params.bufnr, sr - 1, sc - 1, er - 1, range.col, {}), '\n')
                    break
                end
            end

            local arg_text = table.concat(vim.api.nvim_buf_get_text(ctx.params.bufnr, sr - 1, sc - 1, er - 1, ec -1 , {}), '\n')

            table.insert(previous_args, arg_text)
        end

        local ctx_for_completer = vim.tbl_extend("error", {
            arg = relevant_arg,
            previous_args = previous_args,
        }, ctx)
        local result = {}
        for _, completer in ipairs(ls.arg_completers) do
            local completions = completer(ctx_for_completer)
            if completions then
                vim.list_extend(result, vim.iter(completions):map(normalize_completion):totable())
            end

        end
        return result
    end)

    ls:add_completions_ts_generator('((word) @flag (#match? @flag "^-")) @HERE', function(ctx)
        local result = {}
        local real_word = find_real_word_for_completion(ctx)
        local real_word_start_row, real_word_start_col = find_range_of_real_word_for_completion(ctx)
        for flag in pairs(ls.flags) do
            local textEdit = nil
            if real_word_start_row then
                textEdit = {
                    newText = flag,
                    insert = {
                        start = {
                            line = real_word_start_row,
                            character = real_word_start_col,
                        },
                        ['end'] = {
                            line = ctx.params.row - 1,
                            character = ctx.params.col,
                        },
                    },
                }
            end
            table.insert(result, {
                label = flag,
                textEdit = textEdit,
            })
        end
        return result
    end)
    ls:add_completions_ts_generator('((word) @flag (#match? @flag "^-")) @AFTER_HERE', function(ctx)
        local flag_args = ls.flags[ctx:text('flag')]
        if not flag_args then
            return
        end
        local real_word = find_real_word_for_completion(ctx)
        local ctx_for_completer = vim.tbl_extend("error", {
            param_arg = real_word,
        }, ctx)
        local possible_args = flag_args(ctx_for_completer)
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
                table.insert(result, item)
            end
        end
        return result
    end)

    return ls
end

return BufflsForBash
