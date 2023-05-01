local api = vim.api

local config = {
    scretch_dir = vim.fn.stdpath('config') .. '/scretch/',
    default_name = "scretch_",
    default_type = "txt",
    split_cmd = "vsplit",
    mappings = {
        new = "<leader>sn",
        new_named = "<leader>snn",
        last = "<leader>sl",
        search = "<leader>ss",
        grep = "<leader>sg",
        explore = "<leader>sv",
    },
}

local function setup(user_config)
    config = vim.tbl_deep_extend("keep", config, user_config or {})
    vim.fn.mkdir(config.scretch_dir, "p")
    -- Enregistre les mappings
    for action, mapping in pairs(config.mappings) do
        vim.api.nvim_set_keymap("n", mapping, string.format("<cmd>Scretch %s<CR>", action),
            { noremap = true, silent = true })
    end
end


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

-- opens the explorer in the scretch directory
local function explore()
    api.nvim_command("Ex " .. config.scretch_dir)
end

-- returns the path of the most recently modified file in the given directory.
local function get_most_recent_file(dir)
    local most_recent_file
    local most_recent_modification_time = 0
    for _, file in ipairs(vim.fn.readdir(dir)) do
        local file_path = dir .. file
        if vim.fn.getftype(file_path) == "file" then
            local modification_time = vim.loop.fs_stat(file_path).mtime.sec
            if modification_time > most_recent_modification_time then
                most_recent_file = file_path
                most_recent_modification_time = modification_time
            end
        end
    end
    return most_recent_file
end

-- opens the most recently modified scretch file.
local function last()
    local last_file = get_most_recent_file(config.scretch_dir)
    if not last_file then
        print("No scretch file found.")
        return
    end
    local current_bufnr = vim.fn.bufnr('')
    local last_bufnr = vim.fn.bufnr(last_file)
    if current_bufnr == last_bufnr then
        vim.cmd('hide')
    else
        vim.cmd(config.split_cmd .. ' ' .. last_file)
    end
end

local module = {
    new = new,
    new_named = new_named,
    last = last,
    search = search,
    grep = grep,
    setup = setup,
    explore = explore
}

return module
