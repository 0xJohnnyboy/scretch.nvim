# Introduction

Scretch is a plugin to easily create and manage scratch files, called scretch 🙂.

# Installation

This plugin requires Telescope and ripgrep to function.

If you don't have ripgrep installed, I recommend you go check the installation procedure [here](https://github.com/BurntSushi/ripgrep#installation)

You can paste the following code using Packer, or adapt to your favorite package manager:

```lua
use {
  "Sonicfury/scretch",
  requires = 'nvim-telescope/telescope.nvim',
  config = function()
    require("scretch").setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  end
}
```

# Configuration
Here are the default settings used in Scretch
```lua
local config = {
    scretch_dir = vim.fn.stdpath('config') .. '/plugin/scretch/', -- will be created if it doesn't exist
    default_name = "scretch_",
    default_type = "txt", -- default unnamed Scretches are named "scretch_*.txt"
    split_cmd = "vsplit", -- vim split command used when creating a new Scretch
    mappings = {
        new = "<leader>sn", -- creates a new unnamed scretch
        new_named = "<leader>snn", -- prompts you with a name to create a named scretch (you have to provide the extension)
        search = "<leader>ss", -- performs a fuzzy find accross Scretch directory
        grep = "<leader>sg", -- live greps accross Scretch directory
        explore = "<leader>sv", -- opens explorer for easy file mgmt in Scretch directory
    },
}
```
You can copy those settings, update them with your preferences and put them into the setup function to load them.

# Issues

Feel free to open issues if you have a suggestion or encounter a bug. Be kind !

# License

AGPL-3.0, see [license file](./LICENSE.md)

# Contributing

Feel free to open up PRs, they should respect the [contribution guidelines](./CONTRIBUTING.md). Be kind ! 
