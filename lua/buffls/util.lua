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
        local row, col
        if params.lsp_params.position then
            row = params.lsp_params.position.line + 1
            col = params.lsp_params.position.character
        else
            row = params.row
            col = params.col
        end
        return {
            row = row,
            col = col,
            end_row = row,
            end_col = col,
        }
    end
end

return M
