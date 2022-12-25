---@mod BufflsTsQueryHandlerContext TS-based context for handling LSP request

local util = require'buffls.util'

---The context passed to |BufflsTsLs| query-based generators.
---
---Generators registered in |BufflsTsLs:add_ts_generator| receive a context
---object of this type, which they can use to access data from the query's
---match.
---@class BufflsTsQueryHandlerContext
---@field params table the null-ls parameters object
---@field tstree userdata the entire TS tree of the buffer
---@field metadata table the TS query's metadata
---@field nodes {[string]: userdata} the nodes matched by the TS query
local BufflsTsQueryHandlerContext = {}

---@private
BufflsTsQueryHandlerContext.__index = BufflsTsQueryHandlerContext

---Resolve a TS node to the text it represents.
---@param node userdata|string The TreeSitter node to resolve, or the name of that match in self.nodes
---@return string
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

---Check if a the cursor if within a node.
---
---For LSP requests that send a range, this checks if the node overlaps with the range.
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

---Check if a the cursor if after a node.
---@param node userdata|string The TreeSitter node to resolve, or the name of that match in self.nodes
---@return boolean
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
