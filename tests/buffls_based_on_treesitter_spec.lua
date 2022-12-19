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
end)