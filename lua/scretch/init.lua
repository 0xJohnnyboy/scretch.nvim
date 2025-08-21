local config = {
    scretch_dir = vim.fn.stdpath('data') .. '/scretch/',
    template_dir = vim.fn.stdpath('data') .. '/scretch/templates/',
    use_project_dir = {
        auto_create_project_dir = true,
        scretch = false,  -- false | true | auto
        scretch_project_dir = ".scretch/",
        template = false, -- false | true | auto
        template_project_dir = ".scretch/templates/",
    },
    default_name = "scretch_",
    default_type = "txt",
    split_cmd = "vsplit",
    backend = "telescope.builtin",
}

local current_scretch_mode = nil
local current_template_mode = nil
local dirs = {
    scretch = config.scretch_dir,
    template = config.template_dir
}


local function get_scretch_dir()
    local cwd = vim.fn.getcwd()
    local project_scretch = cwd .. '/' .. config.use_project_dir.scretch_project_dir

    -- Forced by command mode
    if current_scretch_mode == "project" then
        vim.fn.mkdir(project_scretch, 'p')
        return project_scretch
    elseif current_scretch_mode == "global" then
        return config.scretch_dir
    end

    -- Auto mode base on settings
    if config.use_project_dir.scretch == true then
        if config.use_project.dir.auto_create_project_dir then
            vim.fn.mkdir(project_scretch, 'p')
        end
        return project_scretch
    elseif config.use_project_dir.scretch == "auto" then
        if vim.fn.isdirectory(project_scretch) == 1 then
            return project_scretch
        end
    end

    return config.scretch_dir
end

local function get_template_dir()
    local cwd = vim.fn.getcwd()
    local project_template = cwd .. '/' .. config.use_project_dir.template_project_dir

    -- Forced by command mode
    if current_template_mode == "project" then
        vim.fn.mkdir(project_template, 'p')
        return project_template
    elseif current_template_mode == "global" then
        return config.template_dir
    end

    -- Auto mode base on settings
    if config.use_project_dir.template == true then
        if config.use_project.dir.auto_create_project_dir then
            vim.fn.mkdir(project_template, 'p')
        end
        return project_template
    elseif config.use_project_dir.template == "auto" then
        if vim.fn.isdirectory(project_template) == 1 then
            return project_template
        end
    end

    return config.template_dir
end

local function update_dirs()
    dirs.scretch = get_scretch_dir()
    dirs.template = get_template_dir()
end


local function change_mode(mode, scretch_or_template)
    local mode_vars = {
        scretch = function(m) current_scretch_mode = m end,
        template = function(m) current_template_mode = m end
    }

    if not mode_vars[scretch_or_template] then
        error("Invalid type: " .. tostring(scretch_or_template))
    end

    if mode == "project" then
        mode_vars[scretch_or_template]("project")
    elseif mode == "global" then
        mode_vars[scretch_or_template]("global")
    elseif mode == "auto" then
        mode_vars[scretch_or_template](nil)
    else
        error("Invalid mode: " .. tostring(mode))
    end
    update_dirs()
end

local function setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
    update_dirs()
end

-- creates a new scretch file in the scretch directory.
local function new()
    local scretch_num = 1
    local scretch_name = dirs.scretch .. config.default_name .. scretch_num .. '.' .. config.default_type
    while vim.loop.fs_stat(scretch_name) do
        scretch_num = scretch_num + 1
        scretch_name = dirs.scretch .. config.default_name .. scretch_num .. '.' .. config.default_type
    end
    vim.cmd(config.split_cmd .. ' ' .. scretch_name)
end

-- creates a new named scretch file in the scretch directory.
local function new_named()
    vim.ui.input({ prompt = 'Scretch name: ' }, function(scretch_name)
        if scretch_name == '' then
            return
        end
        scretch_name = dirs.scretch .. scretch_name
        vim.cmd(config.split_cmd .. ' ' .. scretch_name)
    end)
end

-- performs a fuzzy find across scretch files
local function search()
    if config.backend == "telescope.builtin" then
        return require('telescope.builtin').find_files({
            prompt_title = "Scretch Files",
            cwd = dirs.scretch,
        })
    elseif config.backend == "fzf-lua" then
        return require('fzf-lua').files({
            prompt = "Scretch Files> ",
            cwd = dirs.scretch,
        })
    end
end

-- performs a live grep accross scretch files
local function grep(query)
    if config.backend == "telescope.builtin" then
        return require('telescope.builtin').live_grep({
            prompt_title = "Scretch Search",
            search_dirs = { dirs.scretch },
            live_grep_args = { '--hidden', '-g', '*', query },
            cwd = dirs.scretch,
        })
    elseif config.backend == "fzf-lua" then
        return require("fzf-lua").live_grep({
            prompt = "Scretch Search>",
            cwd = dirs.scretch,
        })
    end
end

-- opens the explorer in the scretch directory
local function explore()
    vim.cmd.edit(dirs.scretch)
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
    local last_file = get_most_recent_file(dirs.scretch)
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
    local template_path = dirs.template .. filename
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
            cwd = dirs.template,
        })
    elseif config.backend == "fzf-lua" then
        return require('fzf-lua').files({
            prompt = "Scretch Templates > ",
            cwd = dirs.template,
        })
    end
end

-- opens finder to create a new scretch from the given template
local function new_from_template()
    if config.backend == "telescope.builtin" then
        require('telescope.builtin').find_files({
            prompt_title = "New Scretch from Template",
            cwd = dirs.template,
            attach_mappings = function(_, map)
                map('i', '<CR>', function()
                    local action_state = require('telescope.actions.state')
                    local new_scretch_name = vim.fn.input('Enter new Scretch name: ')
                    if new_scretch_name ~= '' then
                        local new_scretch_path = dirs.scretch .. new_scretch_name
                        local template_path = action_state.get_selected_entry().path
                        local template_content = vim.fn.readfile(template_path)

                        if template_content then
                            local new_scretch_file = io.open(new_scretch_path, 'w')
                            if new_scretch_file then
                                for _, line in ipairs(template_content) do
                                    new_scretch_file:write(line .. '\n')
                                end
                                new_scretch_file:close()
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
        require('fzf-lua').files({
            prompt = "New Scretch from Template > ",
            cwd = dirs.template,
            actions = {
                ["default"] = function(selected)
                    local new_scretch_name = vim.fn.input('Enter new Scretch name: ')
                    if new_scretch_name ~= '' then
                        local new_scretch_path = dirs.scretch .. new_scretch_name
                        local template_content = vim.fn.readfile(selected[1].path)

                        if template_content then
                            local new_scretch_file = io.open(new_scretch_path, 'w')
                            if new_scretch_file then
                                for _, line in ipairs(template_content) do
                                    new_scretch_file:write(line .. '\n')
                                end
                                new_scretch_file:close()
                                vim.api.nvim_command(':e! ' .. new_scretch_path)
                            else
                                print('Error creating new Scretch file: ' .. new_scretch_path)
                            end
                        else
                            print('Error reading template file: ' .. template_path)
                        end
                    end
                end,
            },
        })
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
    explore = explore,

    scretch_use_project_mode = function() change_mode("project", "scretch") end,
    scretch_use_auto_mode = function() change_mode("auto", "scretch") end,
    scretch_use_global_mode = function() change_mode("global", "scretch") end,
    template_use_project_mode = function() change_mode("project", "template") end,
    template_use_auto_mode = function() change_mode("auto", "template") end,
    template_use_global_mode = function() change_mode("global", "template") end,
}

return module
