---@mod buffls-setup BuffLS setup
---@brief [[
---Register the BuffLS source in null-ls:
--->
---    require'null-ls'.setup {
---        sources = {
---            require'buffls',
---        };
---    }
---<
---@brief ]]

---@mod buffls-basic-usage BuffLS basic usage
---@brief [[
---1. Create a buffer and set it to the appropriate langauge
---2. Create a BuffLS for that buffer: >
---       local bufnr = vim.api.nvim_get_current_buf()
---       local ls = require'buffls.TsLs':for_buffer(bufnr)
---<   Choose the appropriate BuffLS class:
---   - *BufflsTsLs* for using manually written TreeSitter queries. (like in
---     the example)
---   - *BufflsForBash* - a subclass of *BufflsTsLs* with helpers that work
---     with Bash flags.
---   - Custom and/or 3rd party subclasses?
---3. Use `ls` to configure the BuffLS behavior for that buffer (see the
---   documentation of `ls`'s class)
---@brief ]]

local M = {}
return M

