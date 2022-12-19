describe('buffls based on treesitter', function()
    it('Runs code actions', function()
        local ls, client = SingleBufflsWindow('bash', {'echo hello world'})
        local output = {}
        ls:add_action('foo', function()
            table.insert(output, 'foo')
        end)
        ls:add_action('bar', function()
            table.insert(output, 'bar')
        end)
        local actions = client:get_code_actions_as_table(0, 0)
        client:run_action(actions.foo)
        client:run_action(actions.bar)
        client:run_action(actions.foo)
        assert.are.same(output, {'foo', 'bar', 'foo'})
    end)

    it('Suggests completions', function()
        local ls, client = SingleBufflsWindow('bash', {
            'command1 ',
            'command2 ',
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
        ls:add_completions_ts_generator('((command) @HERE (#eq? @HERE "command1"))', function()
            return {{
                label = 'command1-completion',
            }}
        end)
        assert.are.same(client:get_completions(0, 9).items, {{ label = "completion1" }})
        assert.are.same(client:get_completions(1, 9).items, {{ label = "completion2" }})
        assert.are.same(client:get_completions(0, 7).items, {{ label = "command1-completion" }})
    end)
end)
