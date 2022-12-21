---@mod BufflsTsQueryHandlerContext TS-based context for handling LSP request

local util = require'buffls.util'

---@class BufflsTsQueryHandlerContext
---@field params table
---@field tstree userdata
---@field nodes {[string]: userdata}
---@field metadata table
local BufflsTsQueryHandlerContext = {}

---@private
BufflsTsQueryHandlerContext.__index = BufflsTsQueryHandlerContext

---@param node userdata|string The TreeSitter node to resolve, or the name of that match in self.nodes
---@return string?
function BufflsTsQueryHandlerContext:text(node)
    if type(node) == 'string' then
        node = self.nodes[node]
    end
    return vim.treesitter.get_node_text(node, self.params.bufnr)
end

local function node_range(node)
    local sr, sc, er, ec = node:range()
    return sr + 1, sc + 1, er + 1, ec + 1
end

---@param node userdata|string The TreeSitter node to resolve, or the name of that match in self.nodes
---@return boolean
function BufflsTsQueryHandlerContext:is_node_in_range(node)
    if type(node) == 'string' then
        node = self.nodes[node]
    end
    local range = util.normalize_range(self.params)
    local sr, sc, er, ec = node_range(node)
    if range.end_row < sr then
        return false
    end
    if range.end_row == sr and range.end_col < sc then
        return false
    end
    if er < range.row then
        return false
    end
    if er == range.row and ec <= range.col then
        return false
    end
    return true
end

function BufflsTsQueryHandlerContext:is_after_node(node)
    if type(node) == 'string' then
        node = self.nodes[node]
    end
    local range = util.normalize_range(self.params)
    local _, _, sr, sc = node_range(node)
    if range.end_row < sr then
        return false
    end
    if range.end_row == sr and range.end_col < sc then
        return false
    end
    if er < range.row then
        return false
    end
    if er == range.row and ec <= range.col then
        return false
    end
end

return BufflsTsQueryHandlerContext
