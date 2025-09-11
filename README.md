# Introduction

Scretch.nvim is a plugin to easily create and manage scratch files 🙂.

## Features
### New scretch

https://github.com/user-attachments/assets/0fcb1c48-28fe-4ba9-bfc7-231bf8a19459

### New named scretch

https://github.com/user-attachments/assets/35e5e860-b578-4f35-beca-c14e9a0468da

### Search, grep, and explore scretches !

https://github.com/user-attachments/assets/467bdaeb-8c6b-4134-8f18-c651a3f60d74

### Templates

You can save any buffer as a Scretch template. It'll be saved in the default directory if none is explicitely provided in the config.
You can also search and edit templates with Telescope or Fzf-Lua, and create a new Scretch from a template.
See [suggested mappings](#suggested-mappings).

### Scoped scretches

With the project_dir feature, you can tell scretch to create files in you project directory in a dedicated folder.
You can use the config to set this behavior as default, or override temporarily with the dedicated commands (see [suggested mappings](#suggested-mappings)).
You can specify the use for scretch files, templates, or both.

Once you've switched to a project mode, other commands adapt: if you the fuzzy finder with the dedicated functions, it'll search your project scretch directory.

# Installation

This plugin requires Telescope or fzf-lua and ripgrep to function.

If you don't have ripgrep installed, I recommend you go check the installation procedure [here](https://github.com/BurntSushi/ripgrep#installation).
If you don't want to install it, it should fall back to `find`.

You can paste the following code using Packer, or adapt to your favorite package manager:

```lua
-- Lazy
{
  '0xJohnnyboy/scretch.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  -- or
  -- dependencies = { 'ibhagwan/fzf-lua' },
  config = function()
    require('scretch').setup({
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    })
  end,
},
```

```lua  
-- Packer
use {
  '0xJohnnyboy/scretch.nvim',
  requires = 'nvim-telescope/telescope.nvim',
  -- or
  -- requires = 'ibhagwan/fzf-lua' ,
  config = function()
    require('scretch').setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  end
}
```

# Configuration

Here are the default settings used in Scretch:
```lua
local config = {
    scretch_dir = vim.fn.stdpath('data') .. '/scretch/', -- will be created if it doesn't exist
    template_dir = vim.fn.stdpath('data') .. '/scretch/templates', -- will be created if it doesn't exist
    use_project_dir = {
        auto_create_project_dir = false,
        scretch = false,  -- false | true | auto
        scretch_project_dir = ".scretch/",
        template = false, -- false | true | auto
        template_project_dir = ".scretch/templates/",
    },
    default_name = "scretch_",
    default_type = "txt", -- default unnamed Scretches are named "scretch_*.txt"
    split_cmd = "vsplit", -- vim split command used when creating a new Scretch
    backend = "telescope.builtin" -- also accpets "fzf-lua"
}
```
You can copy those settings, update them with your preferences and put them into the setup function to load them.

If your're considering using the project_dir feature, you should add the project_dir to your `.gitignore` (`.scretch` being the default value).

## Suggested mappings

```lua
local s = require("scretch")
vim.keymap.set('n', '<leader>sn', s.new)
vim.keymap.set('n', '<leader>snn', s.new_named)
vim.keymap.set('n', '<leader>sft', s.new_from_template)
vim.keymap.set('n', '<leader>sl', s.last)
vim.keymap.set('n', '<leader>ss', s.search)
vim.keymap.set('n', '<leader>st', s.edit_template)
vim.keymap.set('n', '<leader>sg', s.grep)
vim.keymap.set('n', '<leader>sv', s.explore)
vim.keymap.set('n', '<leader>sat', s.save_as_template)


vim.keymap.set('n', '<leader>smsp' s.scretch_use_project_mode)
vim.keymap.set('n', '<leader>smsa' s.scretch_use_auto_mode)
vim.keymap.set('n', '<leader>smsg' s.scretch_use_global_mode)
vim.keymap.set('n', '<leader>smtp' s.template_use_project_mode)
vim.keymap.set('n', '<leader>smta' s.template_use_auto_mode)
vim.keymap.set('n', '<leader>smtg' s.template_use_global_mode)
```

## Usage
You can use the mappings above, or directly call any function with

```vim
:Scretch <function>
```

For detailed documentation including configuration options, all available functions, and examples:

```vim
:h scretch
```

You can also jump directly to specific sections:
- `:h scretch-configuration` - Configuration options  
- `:h scretch-functions` - All available functions
- `:h scretch-modes` - Understanding global/project/auto modes

# Issues

Feel free to open issues if you have a suggestion or encounter a bug. Be kind !

# License

AGPL-3.0, see [license file](./LICENSE.md)

# Contributing

Feel free to open up PRs, they should respect the [contribution guidelines](./CONTRIBUTING.md). Be kind ! 
