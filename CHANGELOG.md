# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
## 0.1.1 - 2023-04-09
### Fixed
- Replace the deprecated `vim.treesitter.parse_query` with `vim.treesitter.query.parse`.

## 0.1.0 - 2023-01-02
### Added
- null-ls source for routing LSP requests to a `b:buffls` object.
- LSP requests routing based on Treesitter queries.
- A special wrapper for writing buffer langauge servers for Bash.
