local api = vim.api

local config = {
    scretch_dir = vim.fn.stdpath('config') .. '/plugin/scretch/',
    default_name = "scretch_",
    default_type = "txt",
    split_cmd = "vsplit",
    mappings = {
        new = "<leader>sn",
        new_named = "<leader>snn",
        search = "<leader>ss",
        grep = "<leader>sg",
        explore = "<leader>sv",
    },
}

local function setup(user_config)
    config = vim.tbl_deep_extend("keep", config, user_config or {})
    -- Enregistre les mappings
    for action, mapping in pairs(config.mappings) do
        vim.api.nvim_set_keymap("n", mapping, string.format("<cmd>Scretch %s<CR>", action),
            { noremap = true, silent = true })
    end
end

vim.fn.mkdir(config.scretch_dir, "p")

-- creates a new scretch file in the scretch directory.
local function new()
    local scretch_num = 1
    local scretch_name = config.scretch_dir .. config.default_name .. scretch_num .. '.' .. config.default_type
    while vim.fn.filereadable(scretch_name) ~= 0 do
        scretch_num = scretch_num + 1
        scretch_name = config.scretch_dir .. config.default_name .. scretch_num .. '.' .. config.default_type
    end
    api.nvim_command(config.split_cmd .. ' ' .. scretch_name)
end

-- creates a new named scretch file in the scretch directory.
local function new_named()
    local scretch_name = vim.fn.input('Scretch name: ')
    if scretch_name == '' then
        return
    end
    scretch_name = config.scretch_dir .. scretch_name
    api.nvim_command(config.split_cmd .. ' ' .. scretch_name)
end


-- performs a fuzzy find accross scretch files
local function search()
    require('telescope.builtin').find_files({
        prompt_title = "Scretch Files",
        cwd = config.scretch_dir,
        find_command = { 'rg', '--files', '--hidden', '-g', '*' },
    })
end

-- performs a live grep accross scretch files
local function grep(query)
    require('telescope.builtin').live_grep({
        prompt_title = "Scretch Search",
        cwd = config.scretch_dir,
        search_dirs = { config.scretch_dir },
        live_grep_args = { '--hidden', '-g', '*', query },
    })
end

local function explore()
    api.nvim_command("Ex " .. config.scretch_dir)
end


local module = {
    new = new,
    new_named = new_named,
    search = search,
    grep = grep,
    setup = setup,
    explore = explore
}

return module
