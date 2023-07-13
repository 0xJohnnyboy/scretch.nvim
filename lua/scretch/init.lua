local config = {
    scretch_dir = vim.fn.stdpath('config') .. '/scretch/',
    default_name = "scretch_",
    default_type = "txt",
    split_cmd = "vsplit",
    backend = "telescope.builtin",
}

local function setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
    vim.fn.mkdir(config.scretch_dir, "p")
end

-- creates a new scretch file in the scretch directory.
local function new()
    local scretch_num = 1
    local scretch_name = config.scretch_dir .. config.default_name .. scretch_num .. '.' .. config.default_type
    while vim.loop.fs_stat(scretch_name) do
        scretch_num = scretch_num + 1
        scretch_name = config.scretch_dir .. config.default_name .. scretch_num .. '.' .. config.default_type
    end
    vim.cmd(config.split_cmd .. ' ' .. scretch_name)
end

-- creates a new named scretch file in the scretch directory.
local function new_named()
    vim.ui.input({ prompt = 'Scretch name: ' }, function(scretch_name)
        if scretch_name == '' then
            return
        end
        scretch_name = config.scretch_dir .. scretch_name
        vim.cmd(config.split_cmd .. ' ' .. scretch_name)
    end)
end

-- performs a fuzzy find across scretch files
local function search()
    if config.backend == "telescope.builtin" then
        return require('telescope.builtin').find_files({
            prompt_title = "Scretch Files",
            cwd = config.scretch_dir,
        })
    elseif config.backend == "fzf-lua" then
        return require('fzf-lua').files({
            prompt = "Scretch Files> ",
            cwd = config.scretch_dir,
        })
    end
end

local function get_grep_args(backend, query)

end

-- performs a live grep accross scretch files
local function grep(query)
    if config.backend == "telescope.builtin" then
        return require('telescope.builtin').live_grep({
            prompt_title = "Scretch Search",
            search_dirs = { config.scretch_dir },
            live_grep_args = { '--hidden', '-g', '*', query },
            cwd = config.scretch_dir,
        })
    elseif config.backend == "fzf-lua" then
        return require("fzf-lua").live_grep({
            prompt = "Scretch Search>",
            cwd = config.scretch_dir,
        })
    end
end

-- opens the explorer in the scretch directory
local function explore()
    vim.cmd.edit(config.scretch_dir)
end

-- returns the path of the most recently modified file in the given directory.
local function get_most_recent_file(dir)
    local most_recent_file
    local most_recent_modification_time = 0
    for _, file in ipairs(vim.fn.readdir(dir)) do
        local file_path = dir .. file
        local file_stats = vim.loop.fs_stat(file_path)
        if file_stats.type == "file" then
            local modification_time = file_stats.mtime.sec
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
        vim.notify("No scretch file found.", vim.log.levels.ERROR)
        return
    end
    local current_bufnr = vim.fn.bufnr('')
    local last_bufnr = vim.fn.bufnr(last_file)
    if current_bufnr ~= last_bufnr then
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
