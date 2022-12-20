describe('BuffLS for Bash', function()
    it('Suggests completions', function()
        local ls, client = SingleBufflsWindow('bash', {
            'command --foo bar --baz qux',
        })

        local bash_ls = require'buffls/ForBash':wrap(ls)
        bash_ls:add_flag('--baz', function()
            return {{
                label = 'qux',
            }}
        end)
        bash_ls:add_flag('--foo', {'bar'})
        vim.api.nvim_win_set_cursor(0, {1, 10})
        assert.are.same(client:get_completion_labels_sorted(), {'--baz', '--foo'})
        vim.api.nvim_win_set_cursor(0, {1, 14})
        assert.are.same(client:get_completion_labels_sorted(), {"bar"})
        vim.api.nvim_win_set_cursor(0, {1, 24})
        assert.are.same(client:get_completion_labels_sorted(), {"qux"})
    end)
end)
