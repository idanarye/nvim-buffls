vim.opt.runtimepath:append { '.' }
vim.opt.runtimepath:append { '../plenary.nvim' }
vim.opt.runtimepath:append { '../null-ls.nvim' }
vim.opt.runtimepath:append { '../nvim-treesitter' }

require'null-ls'.setup {
    sources = {
        require'buffls'.null_ls_source,
    },
}
require'nvim-treesitter.configs'.setup {
    ensure_installed = { "bash" };
    sync_install = true,
}

function EnsureSingleWindow()
    local wins = vim.api.nvim_list_wins()
    vim.cmd.new()
    for _, winnr in ipairs(wins) do
        vim.api.nvim_win_close(winnr, true)
    end
end

local buffls_file_nr = 0
function SingleBufflsWindow(filetype, lines)
    buffls_file_nr = buffls_file_nr + 1
    vim.cmd.setfiletype(filetype)
    vim.cmd.file('buffls-test-buffer-' .. vim.loop.getpid() .. '-' .. buffls_file_nr)
    vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
    local ls = require'buffls'.BufflsTsLs:for_buffer(vim.api.nvim_get_current_buf())
    local client = WaitFor(1, function()
        return require'tests/LspClientWrapper':new(0)
    end)
    return ls, client
end

function Sleep(duration)
    local co = coroutine.running()
    vim.defer_fn(function()
        coroutine.resume(co)
    end, duration)
    coroutine.yield()
end

function WaitFor(timeout_secs, pred, sleep_ms)
    local init_time = vim.loop.uptime()
    local last_time = init_time + timeout_secs
    while true do
        local iteration_time = vim.loop.uptime()
        local result = {pred()}
        if result[1] then
            return unpack(result)
        end
        if last_time < iteration_time then
            error('Took too long (' .. (iteration_time - init_time) .. ' seconds)')
        end
        Sleep(sleep_ms or 10)
    end
end
