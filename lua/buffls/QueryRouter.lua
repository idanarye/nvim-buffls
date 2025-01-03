---@mod buffls.QueryRouter Router for specific LSP request type

local util = require'buffls.util'

---Responsible for a single type of LSP request that a buffer LS handles. For
---each such request, it'll run all the generators registered on it and
---concatenate their results.
---@class BufflsQueryRouter
---@field private direct_generators function[]
local BufflsQueryRouter = {}
BufflsQueryRouter.__index = BufflsQueryRouter

---@private
---@return BufflsQueryRouter
function BufflsQueryRouter:new(language)
    return setmetatable({
        language = language,
        direct_generators = {},
    }, self)
end

---Register a function that receives the parameters object from none-ls and
---returns a result in none-ls' format. This means that it needs to return a
---list of results.
---@param generator function
function BufflsQueryRouter:add_direct_generator(generator)
    table.insert(self.direct_generators, generator)
end

---@protected
function BufflsQueryRouter:call_all(params)
    local results = {}
    local results_len = 0

    for _, generator in ipairs(self.direct_generators) do
        util.resilient(function()
            local handler_result = generator(params)
            if handler_result then
                for _, item in ipairs(handler_result) do
                    results_len = results_len + 1
                    results[results_len] = item
                end
            end
        end)
    end
    if 0 < results_len then
        return results
    end
end

---@private
function BufflsQueryRouter:__call(ls, params)
    if params == nil then
        params = ls
    end
    return self:call_all(params)
end

return BufflsQueryRouter
