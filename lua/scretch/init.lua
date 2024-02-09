local config = {
    scretch_dir = vim.fn.stdpath('config') .. '/scretch/',
    template_dir = vim.fn.stdpath('data') .. '/scretch/templates/',
    default_name = "scretch_",
    default_type = "txt",
    split_cmd = "vsplit",
    backend = "telescope.builtin",
}

local function setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
    vim.fn.mkdir(config.scretch_dir, "p")
    vim.fn.mkdir(config.template_dir, "p")
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

-- saves current buffer as scretch template
local function save_as_template()
    local buffer = vim.api.nvim_get_current_buf()
    local filename = vim.fn.input('Enter template name: ')
    local template_path = config.template_dir .. filename
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

    local file, err = io.open(template_path, 'w')
    if not file then
        print('Error opening file: ' .. err)
        return
    end
    for _, line in ipairs(lines) do
        file:write(line .. '\n')
    end
    file:close()
end

-- opens finder for editing templates
local function edit_template()
    if config.backend == "telescope.builtin" then
        return require('telescope.builtin').find_files({
            prompt_title = "Scretch Templates",
            cwd = config.template_dir,
        })
    elseif config.backend == "fzf-lua" then
        return require('fzf-lua').files({
            prompt = "Scretch Templates > ",
            cwd = config.template_dir,
        })
    end
end

-- opens finder to create a new scretch from the given template
local function new_from_template()
    if config.backend == "telescope.builtin" then
        require('telescope.builtin').find_files({
            prompt_title = "New Scretch from Template",
            cwd = config.template_dir,
            attach_mappings = function(_, map)
                map('i', '<CR>', function()
                    local action_state = require('telescope.actions.state')
                    local new_scretch_name = vim.fn.input('Enter new Scretch name: ')
                    if new_scretch_name ~= '' then
                        local new_scretch_path = config.scretch_dir .. new_scretch_name
                        local template_path = action_state.get_selected_entry().path
                        local template_content = vim.fn.readfile(template_path)

                        if template_content then
                            local new_scretch_file = io.open(new_scretch_path, 'w')
                            if new_scretch_file then
                                for _, line in ipairs(template_content) do
                                    new_scretch_file:write(line .. '\n')
                                end
                                new_scretch_file:close()
                                -- vim.cmd('edit ' .. new_scretch_path)
                                vim.api.nvim_command(":e! " .. new_scretch_path)
                            else
                                print('Error opening file for writing: ' .. new_scretch_path)
                            end
                        else
                            print('Error reading template file: ' .. template_path)
                        end
                    end
                end)
                return true
            end,
        })
    elseif config.backend == "fzf-lua" then
        -- todo : new scretch from template with fzf-lua
        print('Not implemented')
    end
end

local module = {
    new = new,
    new_named = new_named,
    save_as_template = save_as_template,
    new_from_template = new_from_template,
    edit_template = edit_template,
    last = last,
    search = search,
    grep = grep,
    setup = setup,
    explore = explore
}

return module
