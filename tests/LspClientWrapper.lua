local LspClientWrapper = {}

function LspClientWrapper:new(bufnr)
    if bufnr == 0 then
        bufnr = vim.api.nvim_get_current_buf()
    end
    local client = unpack(vim.lsp.get_active_clients{ name = 'null-ls', bufnr = bufnr })
    if client == nil then
        return nil
    end
    return setmetatable({
        bufnr = bufnr,
        client = client,
    }, {__index = self})
end

function LspClientWrapper:text_document()
    return {
        uri = vim.uri_from_bufnr(self.bufnr)
    }
end

function LspClientWrapper:get_position_from_cursor()
    if vim.api.nvim_get_current_buf() ~= self.bufnr then
        error('Cannot call client.position unless in the buffer')
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    return {
        line = cursor[1] - 1,
        character = cursor[2],
    }
end

function LspClientWrapper:request_async(command, params)
    local co = coroutine.running()
    self.client.request(command, params, function(_, result)
        coroutine.resume(co, result)
    end)
    return coroutine.yield()
end

function LspClientWrapper:get_code_actions()
    local pos = self:get_position_from_cursor()
    return self:request_async('textDocument/codeAction', {
        textDocument = self:text_document(),
        range = {start = pos, ['end'] = pos},
    })
end

function LspClientWrapper:get_code_actions_as_table()
    local result = {}
    for _, action in ipairs(self:get_code_actions()) do
        result[action.title] = action
    end
    return result
end

function LspClientWrapper:run_action(action)
    self.client.request('workspace/executeCommand', {
        command = action.command,
        arguments = action.arguments,
    })
end

function LspClientWrapper:get_completions()
    return self:request_async('textDocument/completion', {
        textDocument = self:text_document(),
        position = self:get_position_from_cursor(),
    })
end

function LspClientWrapper:get_completion_labels_sorted()
    local completions = self:get_completions()
    local completion_labels = vim.tbl_map(function(c) return c.label end, completions.items)
    return vim.fn.sort(completion_labels)
end

return LspClientWrapper
