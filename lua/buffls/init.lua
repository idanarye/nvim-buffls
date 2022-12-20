---@mod buffls BuffLS - Buffer Specific null-ls Source
---@brief [[
---BuffLS is a null-ls source for adding LSP-like functionality for a specific
---buffer. This is useful for small scripts that use Neovim buffers for input,
---and want to enhance their UX with things like custom completion or code
---actions. Writing a separate null-ls source for each such script is too
---cumbersome, so BuffLS acts as a single source that redirects the LSP
---requests to objects stored in a buffer variable.
---
---BuffLS was created as a supplemental plugin for Moonicipal
---(https://github.com/idanarye/nvim-moonicipal), but can be used independent
---of it.
---@brief ]]
local M = {}

local null_ls = require'null-ls'

local util = require'buffls/util'

local LSP_METHODS_TO_OBJECT_METHODS = {
    [null_ls.methods.CODE_ACTION] = "actions",
    [null_ls.methods.DIAGNOSTICS] = "diagnostics",
    [null_ls.methods.DIAGNOSTICS_ON_OPEN] = "diagnostics",
    [null_ls.methods.DIAGNOSTICS_ON_SAVE] = "diagnostics",
    [null_ls.methods.FORMATTING] = "formatting",
    [null_ls.methods.RANGE_FORMATTING] = "formatting",
    [null_ls.methods.HOVER] = "hover",
    [null_ls.methods.COMPLETION] = "completion",
}

M.null_ls_source = {
    name = 'buffls-proxy',
    method = vim.tbl_keys(LSP_METHODS_TO_OBJECT_METHODS),
    filetypes = { '_all' },
    generator = {
        fn = function(params)
            local found, obj = pcall(vim.api.nvim_buf_get_var, params.bufnr, 'buffls')
            if not found then
                return
            end
            if type(obj) == 'function' then
                obj = obj()
            end
            local method_name = LSP_METHODS_TO_OBJECT_METHODS[params.method]
            local method = obj[method_name]
            if method == nil then
                return
            end
            local success, result = util.resilient(method, obj, params)
            if success then
                return result
            end
        end
    }
}

return M
