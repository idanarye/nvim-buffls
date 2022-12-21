[![CI Status](https://github.com/idanarye/nvim-buffls/workflows/CI/badge.svg)](https://github.com/idanarye/buffls/actions)

INTRODUCTION
============

BuffLS is a null-ls source for adding LSP-like functionality for a specific buffer. This is useful for small scripts that use Neovim buffers for input, and want to enhance their UX with things like custom completion or code actions. Writing a separate null-ls source for each such script is too cumbersome, so BuffLS acts as a single source that redirects the LSP requests to objects stored in a buffer variable.

BuffLS was created as a supplemental plugin for [Moonicipal](https://github.com/idanarye/nvim-moonicipal), but can be used independent of it.

CONTRIBUTION GUIDELINES
=======================

* If your contribution can be reasonably tested with automation tests, add tests. The tests run with [a specific branch in a fork of Plenary](https://github.com/idanarye/plenary.nvim/tree/async-testing) that allows async testing ([there is a PR to include it in the main repo](https://github.com/nvim-lua/plenary.nvim/pull/426)) 
* Documentation comments must be compatible with both [Sumneko Language Server](https://github.com/sumneko/lua-language-server/wiki/Annotations) and [lemmy-help](https://github.com/numToStr/lemmy-help/blob/master/emmylua.md). If you do something that changes the documentation, please run `make docs` to update the vimdoc.
* Update the changelog according to the [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) format.
