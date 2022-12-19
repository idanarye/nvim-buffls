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

function LspClientWrapper:request_async(command, params)
    local co = coroutine.running()
    self.client.request(command, params, function(_, result)
        coroutine.resume(co, result)
    end)
    return coroutine.yield()
end

function LspClientWrapper:get_code_actions(line, character)
    local pos = {line = line, character = character}
    return self:request_async('textDocument/codeAction', {
        textDocument = self:text_document(),
        range = {start = pos, ['end'] = pos},
    })
end

function LspClientWrapper:get_code_actions_as_table(line, character)
    local result = {}
    for _, action in ipairs(self:get_code_actions(line, character)) do
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

return LspClientWrapper
