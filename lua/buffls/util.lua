local M = {}

function M.resilient(fn, ...)
    xpcall(fn, function(err)
        vim.api.nvim_err_writeln(debug.traceback(err, 2))
    end, ...)
end

return M
