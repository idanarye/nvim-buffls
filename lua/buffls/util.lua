local M = {}

function M.resilient(fn, ...)
    return xpcall(fn, function(error)
        if type(error) ~= 'string' then
            error = vim.inspect(error)
        end
        local traceback = debug.traceback(error, 2)
        traceback = string.gsub(traceback, '\t', string.rep(' ', 8))
        vim.api.nvim_err_writeln(traceback)
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

function M.defer_to_coroutine(dlg, ...)
    local co = coroutine.create(function(...)
        xpcall(dlg, function(err)
            if type(err) ~= 'string' then
                err = vim.inspect(err)
            end
            local traceback = debug.traceback(err, 2)
            traceback = string.gsub(traceback, '\t', string.rep(' ', 8))
            vim.notify(traceback, vim.log.levels.ERROR, {
                title = 'ERROR in a coroutine'
            })
        end, ...)
    end)
    coroutine.resume(co, ...)
    return co
end

return M
