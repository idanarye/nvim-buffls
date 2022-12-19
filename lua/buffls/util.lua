local M = {}

function M.resilient(fn, ...)
    xpcall(fn, function(err)
        vim.api.nvim_err_writeln(debug.traceback(err, 2))
    end, ...)
end

function M.normalize_range(params)
    if params.lsp_params.range then
        return params.range
    else
        return {
            row = params.row,
            col = params.col,
            end_row = params.row,
            end_col = params.col,
        }
    end
end

return M
