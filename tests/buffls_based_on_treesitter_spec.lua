describe('BuffLS based on treesitter', function()
    it('Runs code actions', function()
        local ls, client = SingleBufflsWindow('bash', {'echo hello world'})
        local output = {}
        ls:add_action('foo', function()
            table.insert(output, 'foo')
        end)
        ls:add_action('bar', function()
            table.insert(output, 'bar')
        end)
        local actions = client:get_code_actions_as_table()
        client:run_action(actions.foo)
        client:run_action(actions.bar)
        client:run_action(actions.foo)
        assert.are.same(output, {'foo', 'bar', 'foo'})
    end)

    it('Suggests completions', function()
        local ls, client = SingleBufflsWindow('bash', {
            'command1 ',
            'command2 ',
            'command3 ',
        })
        ls:add_completions_ts_generator('((command) @AFTER_HERE (#eq? @AFTER_HERE "command1"))', function()
            return {{
                label = 'completion1',
            }}
        end)
        ls:add_completions_ts_generator('((command) @AFTER_HERE (#eq? @AFTER_HERE "command2"))', function()
            return {{
                label = 'completion2',
            }}
        end)
        ls:add_completions_ts_generator('((command) @HERE (#eq? @HERE "command3"))', function()
            return {{
                label = 'command3-completion',
            }}
        end)
        vim.api.nvim_win_set_cursor(0, {1, 10})
        assert.are.same(client:get_completion_labels_sorted(), {"completion1"})
        vim.api.nvim_win_set_cursor(0, {2, 9})
        assert.are.same(client:get_completion_labels_sorted(), {"completion2"})
        vim.api.nvim_win_set_cursor(0, {3, 7})
        assert.are.same(client:get_completion_labels_sorted(), {"command3-completion"})
    end)
end)
