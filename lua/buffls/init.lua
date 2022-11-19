local M = {}

local null_ls = require'null-ls'

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
            local method_name = LSP_METHODS_TO_OBJECT_METHODS[params.method]
            local method = obj[method_name]
            if method == nil then
                return
            end
            return method(obj, params)
        end
    }
}

return M
