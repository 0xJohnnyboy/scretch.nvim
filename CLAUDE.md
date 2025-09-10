# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Scretch.nvim is a Neovim plugin for creating and managing scratch files. It provides functionality for creating temporary files, templates, and organizing them either globally or per-project.

## Architecture

### Core Structure
- `lua/scretch/init.lua` - Main plugin module containing all functionality
- `plugin/scretch.lua` - Plugin entry point with command definitions and completion

### Key Components

**Configuration System**: The plugin uses a configuration table with defaults that can be overridden via `setup()`. Key settings include:
- Directory paths for scratch files and templates (global vs project-local)
- Backend selection (telescope.builtin or fzf-lua)
- File naming conventions and split commands

**Directory Management**: Dynamic directory resolution based on mode:
- Global mode: Uses `vim.fn.stdpath('data')/scretch/`
- Project mode: Uses `.scretch/` in current working directory  
- Auto mode: Falls back to project if directory exists, otherwise global

**Mode System**: Runtime switching between global/project/auto modes for both scratch files and templates via `current_scretch_mode` and `current_template_mode` variables.

### Dependencies
- Requires either Telescope (`nvim-telescope/telescope.nvim`) or fzf-lua (`ibhagwan/fzf-lua`)
- Optional: ripgrep for enhanced search functionality

## Development Commands

This is a Lua-based Neovim plugin with no build system. Testing is manual through Neovim usage.

## Key Functions

All functions are exposed through the main module table:
- File creation: `new()`, `new_named()`, `new_from_template()`
- File management: `last()`, `search()`, `grep()`, `explore()`
- Templates: `save_as_template()`, `edit_template()`
- Mode switching: `*_use_project_mode()`, `*_use_auto_mode()`, `*_use_global_mode()`

## Contributing Guidelines

From CONTRIBUTING.md:
- Use Conventional Commits format
- Commits should be atomic with extensive messages if needed
- Bug reports require reproduction steps and environment details
- Enhancement suggestions need clear descriptions and use cases

## Plugin Integration

The plugin registers a `:Scretch` command with tab completion for all public functions (excluding `setup`). Default command without arguments executes `new()`.