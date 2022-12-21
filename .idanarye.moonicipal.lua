local moonicipal = require'moonicipal'
local T = moonicipal.tasks_file()

function T:doc()
    vim.fn.system('make docs')
    vim.cmd.checktime()
    --require'idan'.generate_docs()
end

function T:query()
    vim.cmd.messages()
end

function T:refresh()
    require'idan'.unload_package[[^buffls\>]]
    vim.diagnostic.reset()
    require'null-ls'.reset_sources()
    require'null-ls'.register(require'buffls'.null_ls_source)
end

function T:launch()
    return self:cached_buf_in_tab(function()
        vim.cmd[[
        botright new moonicipal:datacell:launch
        setfiletype bash
        set buftype=nowrite
        set bufhidden=wipe
        ]]
        vim.api.nvim_buf_set_lines(0, 0, -1, true, {
             'echo one two --foo bar --baz qux',
            -- 'command --foo bar --baz qux',

            --'command1 ',
            --'command2 ',
            --'command3 ',
        })

        return vim.api.nvim_get_current_buf()
    end)
end

function T:run()
    vim.cmd.messages('clear')
    local buf = T:launch()
    local ls = require'buffls/TsLs':for_buffer(buf)

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

    -- ls:add_completions_ts_generator('(_ argument: (word) @key (#any-of? @key "--foo" "--baz") . argument: (word) @arg @HERE)', function(ctx)
        -- print("hi")
        -- return {{
            -- label = ctx.params.word_to_complete .. '-is-(' .. ctx:text('key') .. ':' .. ctx:text('arg') .. ')',
            -- documentation = vim.inspect{
                -- params = ctx.params,
                -- here_range = {ctx.nodes.HERE:range()},
                -- metadata = ctx.metadata,
            -- },
        -- }}
    -- end)

    ls:add_action('Print hello world', function()
        moonicipal.fix_echo()
        print('hello world')
    end)
    ls:add_action('Print params', function(params)
        moonicipal.fix_echo()
        dump(params)
    end)
    return buf
end

T{alias=':0'}
function T:open_bash_buffer()
    local bufnr = self:cached_buf_in_tab(function()
        vim.cmd[[
        botright new
        setfiletype bash
        set buftype=nofile
        ]]
        vim.api.nvim_buf_set_lines(0, 0, -1, true, {
            'echo one two --foo bar',
        })
        return vim.api.nvim_buf_get_number(0)
    end)
    return bufnr, vim.treesitter.get_parser(bufnr)
end

--function T:act()
    --local bufnr, parser = T:open_bash_buffer()
    --local parsed = parser:parse()[1]
    --local root = parsed:root()
    --print(root:sexpr())
    ----for id, node, metadata in vim.treesitter.query.parse_query('bash', '(_ argument: (word) @arg)'):iter_matches(root, bufnr) do
    --Q = vim.treesitter.query.parse_query('bash', '[(program) @foo (_ argument: (word) @bar)]')
    --for id, node, metadata in Q:iter_matches(root, bufnr) do
        --local captures = {}
        --for i, v in pairs(node) do
            --captures[Q.captures[i]] = v
        --end
        --dump(id, captures, metadata)
        ---- for _, m in ipairs(match) do
            ---- local rng = {m:range()}
            ---- rng[5] = {}
            ---- dump(vim.api.nvim_buf_get_text(bufnr, unpack(rng)))
        ---- end
        ----ud = (match[1])
    --end
--end

--function T:go()
    --local BufflsTsLs = dofile'lua/buffls/based_on_treesitter.lua'.BufflsTsLs
    --print('new', BufflsTsLs:new():for_buffer())
    --print('cls', BufflsTsLs:for_buffer())
--end

local function get_lsp_client()
    return unpack(vim.lsp.get_active_clients{ bufnr = T:run(), name = 'null-ls' })
end
function T:act()
    vim.cmd.messages('clear')
    local buf = T:launch()
    ls = require'buffls/ForBash':for_buffer(buf)
    ls:add_action('Print params', function(params)
        moonicipal.fix_echo()
        dump(params)
        dump(vim.api.nvim_win_get_cursor(0))
    end)
    -- ls:add_flag('--foo', {'--foobar'})
    ls:add_flag('--foo', {'bar'})
    --ls:add_completions_ts_generator('((command) @AFTER_HERE (#eq? @AFTER_HERE "command1"))', function(ctx)
        --return {{
            --label = 'completion1',
        --}}
    --end)
    --ls:add_completions_ts_generator('((command) @AFTER_HERE (#eq? @AFTER_HERE "command2"))', function(ctx)
        --return {{
            --label = 'completion2',
        --}}
    --end)
end

function T:test()
    vim.cmd'botright new'
    vim.cmd.wincmd('20_')
    vim.cmd'terminal make test'
    vim.cmd.startinsert()
end
