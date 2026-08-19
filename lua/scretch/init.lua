local config = {
    scretch_dir = vim.fn.stdpath('data') .. '/scretch/',
    template_dir = vim.fn.stdpath('data') .. '/scretch/templates/',
    use_project_dir = {
        auto_create_project_dir = false,
        scretch = false,  -- false | true | auto
        scretch_project_dir = ".scretch/",
        template = false, -- false | true | auto
        template_project_dir = ".scretch/templates/",
    },
    default_name = "scretch_",
    default_type = "txt",
    split_cmd = "vsplit",
    backend = "telescope.builtin",
    template_variables = {
        enabled = true,
        date = {
            enabled = true,
            value = "now",
            default_format = "YYYY-MM-dd",
        },
        title = {
            enabled = true,
            source = "filename",
        },
        author = {
            enabled = true,
            source = "shell", -- shell | git | literal
            value = "",
        },
        custom = {},
    },
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
        if config.use_project_dir.auto_create_project_dir then
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
        if config.use_project_dir.auto_create_project_dir then
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

local function format_date(fmt, timestamp)
    local os_fmt = fmt or "YYYY-MM-dd"
    os_fmt = os_fmt:gsub("YYYY", "%%Y")
        :gsub("MM", "%%m")
        :gsub("dd", "%%d")
        :gsub("HH", "%%H")
        :gsub("mm", "%%M")
        :gsub("ss", "%%S")
    return os.date(os_fmt, timestamp)
end

local function get_title_from_path(path)
    local filename = vim.fn.fnamemodify(path, ":t")
    local title = vim.fn.fnamemodify(filename, ":r")
    return title
end

local function resolve_author_value()
    local author_cfg = config.template_variables.author or {}
    local source = author_cfg.source or "shell"
    if source == "literal" then
        return author_cfg.value or ""
    end
    if source == "git" then
        local git_name = vim.fn.system("git config user.name")
        if vim.v.shell_error == 0 then
            return vim.trim(git_name)
        end
        return ""
    end
    return vim.env.USER or ""
end

local function warn_template_variable(msg)
    vim.notify("[scretch] template variable warning: " .. msg, vim.log.levels.WARN)
end

local function parse_template_expression(expr)
    local trimmed = vim.trim(expr)
    local parts = vim.split(trimmed, "|", { plain = true, trimempty = true })
    if #parts == 0 then
        return nil, {}
    end
    local var_name = vim.trim(parts[1])
    local filters = {}
    for i = 2, #parts do
        local filter_part = vim.trim(parts[i])
        local filter_tokens = vim.split(filter_part, ":", { plain = true, trimempty = true })
        local filter_name = vim.trim(filter_tokens[1] or "")
        local args = {}
        for j = 2, #filter_tokens do
            args[#args + 1] = vim.trim(filter_tokens[j])
        end
        filters[#filters + 1] = { name = filter_name, args = args }
    end
    return var_name, filters
end

local function resolve_template_variable(var_name, ctx)
    local vars_cfg = config.template_variables or {}
    if var_name == "title" then
        if vars_cfg.title and vars_cfg.title.enabled == false then
            warn_template_variable("variable 'title' is disabled")
            return ""
        end
        return ctx.title
    elseif var_name == "date" then
        if vars_cfg.date and vars_cfg.date.enabled == false then
            warn_template_variable("variable 'date' is disabled")
            return ""
        end
        local date_value = (vars_cfg.date and vars_cfg.date.value) or "now"
        if date_value == "now" then
            return format_date((vars_cfg.date or {}).default_format, ctx.now)
        end
        return tostring(date_value)
    elseif var_name == "author" then
        if vars_cfg.author and vars_cfg.author.enabled == false then
            warn_template_variable("variable 'author' is disabled")
            return ""
        end
        return resolve_author_value()
    end

    local custom_vars = vars_cfg.custom or {}
    local custom = custom_vars[var_name]
    if type(custom) == "function" then
        local ok, value = pcall(custom, ctx)
        if not ok then
            warn_template_variable("custom variable '" .. var_name .. "' failed: " .. tostring(value))
            return ""
        end
        return value == nil and "" or tostring(value)
    end

    warn_template_variable("unknown variable '" .. var_name .. "'")
    return ""
end

local function apply_template_filter(value, filter, ctx)
    if filter.name == "uppercase" then
        return string.upper(value)
    elseif filter.name == "lowercase" then
        return string.lower(value)
    elseif filter.name == "trim" then
        return vim.trim(value)
    elseif filter.name == "format" then
        if #filter.args < 1 then
            warn_template_variable("filter 'format' requires one argument")
            return ""
        end
        local fmt = filter.args[1]
        if ctx.current_var == "date" then
            return format_date(fmt, ctx.now)
        end
        return value
    end

    warn_template_variable("unknown filter '" .. tostring(filter.name) .. "'")
    return ""
end

local function render_template_line(line, ctx)
    local rendered = line:gsub("{{(.-)}}", function(expr)
        local var_name, filters = parse_template_expression(expr)
        if not var_name or var_name == "" then
            warn_template_variable("empty expression")
            return ""
        end
        local value = resolve_template_variable(var_name, ctx)
        value = value == nil and "" or tostring(value)
        ctx.current_var = var_name
        for _, filter in ipairs(filters) do
            if not filter.name or filter.name == "" then
                warn_template_variable("invalid filter in expression '" .. expr .. "'")
                return ""
            end
            value = apply_template_filter(value, filter, ctx)
        end
        return value
    end)
    return rendered
end

local function render_template_content(template_content, template_path, new_scretch_path)
    local vars_cfg = config.template_variables or {}
    if vars_cfg.enabled == false then
        return template_content
    end

    local ctx = {
        now = os.time(),
        template_path = template_path,
        new_file_path = new_scretch_path,
        new_file_name = vim.fn.fnamemodify(new_scretch_path, ":t"),
        title = get_title_from_path(new_scretch_path),
        cwd = vim.fn.getcwd(),
    }

    local out = {}
    for _, line in ipairs(template_content) do
        out[#out + 1] = render_template_line(line, ctx)
    end
    return out
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
        if file_stats and file_stats.type == "file" then
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
                            template_content = render_template_content(template_content, template_path, new_scretch_path)
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
                        local template_path = selected[1].path
                        local template_content = vim.fn.readfile(template_path)

                        if template_content then
                            template_content = render_template_content(template_content, template_path, new_scretch_path)
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
    _internal = {
        render_template_content = render_template_content,
        parse_template_expression = parse_template_expression,
        update_dirs = update_dirs,
        get_most_recent_file = get_most_recent_file,
    }
}

return module
