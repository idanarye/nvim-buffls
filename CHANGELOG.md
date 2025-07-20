# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.1.0](https://github.com/idanarye/nvim-buffls/compare/v0.1.0...v0.2.0) (2025-07-20)


### ⚠ BREAKING CHANGES

* `BufflsForBash:add_flag` generator function receive a context object rather then the flag arg
* Direct generators receive a context objects with the `params` as a field instead of just `params` directly

### Features

* `BufflsForBash:add_flag` generator function receive a context object rather then the flag arg ([21bbfca](https://github.com/idanarye/nvim-buffls/commit/21bbfcab47be33cc17f854e2e5ac281ff953a3b3))
* Add `buffls.LineListLs` - a buffls for working with a simple text buffer that represents a list of lines ([d562e85](https://github.com/idanarye/nvim-buffls/commit/d562e85a4a6f681d9c606ebb46e8d95502f341b9))
* Add `BufflsForBash:add_cli_arg` ([df5516b](https://github.com/idanarye/nvim-buffls/commit/df5516b0393bdfcd01bee04848650b87e00c2cc0))
* Direct generators receive a context objects with the `params` as a field instead of just `params` directly ([bd4d804](https://github.com/idanarye/nvim-buffls/commit/bd4d8047e0528f52de97bbb8389e2014600dd2dc))
* Improve `BufflsForBash:for_buffer` ([885c742](https://github.com/idanarye/nvim-buffls/commit/885c7427d8ce407489cd4ba1956886d0b9ca63c2))


### Bug Fixes

* Flag completion for `BufflsForBash` ending up with double `--` ([6ea0361](https://github.com/idanarye/nvim-buffls/commit/6ea036121d22021a368ebda0c6af73bea2c3e055))
* Use `{all = false}` when using `iter_matches` ([842bb53](https://github.com/idanarye/nvim-buffls/commit/842bb5387ade7f5fcb009abd5a4816bd8476c4d5))

## [Unreleased]

## 0.1.1 - 2023-04-09
### Fixed
- Replace the deprecated `vim.treesitter.parse_query` with `vim.treesitter.query.parse`.

### Removed
- [**BREAKING**] Hover support, since the builtin `vim.lsp.hover` kept
  complaining about the empty responses.

## 0.1.0 - 2023-01-02
### Added
- null-ls source for routing LSP requests to a `b:buffls` object.
- LSP requests routing based on Treesitter queries.
- A special wrapper for writing buffer langauge servers for Bash.
