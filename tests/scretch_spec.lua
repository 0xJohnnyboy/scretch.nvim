local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error((msg or "assertion failed") .. ("\nexpected: %s\nactual: %s"):format(vim.inspect(expected), vim.inspect(actual)))
    end
end

local function assert_truthy(value, msg)
    if not value then
        error(msg or "expected truthy value")
    end
end

local function with_module(test_fn)
    local cmds = {}
    local notifications = {}
    local fs = {}
    local cwd = "/tmp/scretch-tests"
    local created_dirs = {}
    local files = {}
    local input_value = ""
    local current_buf = 1
    local current_file = ""

    local function split_plain(str, sep)
        local out = {}
        if str == "" then
            return out
        end
        sep = sep or "%s+"
        if sep == "%s+" then
            for part in str:gmatch("%S+") do
                out[#out + 1] = part
            end
            return out
        end
        local start = 1
        while true do
            local s, e = str:find(sep, start, true)
            if not s then
                out[#out + 1] = str:sub(start)
                break
            end
            out[#out + 1] = str:sub(start, s - 1)
            start = e + 1
        end
        return out
    end

    local v = vim
    v.env = { USER = "shell-user" }
    v.log = { levels = { WARN = "WARN", ERROR = "ERROR" } }
    v.loop = v.loop or {}
    v.loop.fs_stat = function(path)
        return fs[path]
    end
    v.fn.stdpath = function()
        return "/tmp/nvim-data"
    end
    v.fn.getcwd = function()
        return cwd
    end
    v.fn.mkdir = function(path)
        created_dirs[path] = true
    end
    v.fn.isdirectory = function(path)
        return created_dirs[path] and 1 or 0
    end
    v.fn.input = function()
        return input_value
    end
    v.fn.readfile = function(path)
        return files[path]
    end
    v.fn.readdir = function()
        return { "a.txt", "b.txt" }
    end
    v.fn.bufnr = function(arg)
        if arg == "" then
            return current_buf
        end
        if arg == current_file then
            return current_buf
        end
        return 999
    end
    v.fn.system = function(cmd)
        if cmd == "git config user.name" then
            return "git-user\n"
        end
        return ""
    end
    v.fn.fnamemodify = function(path, mod)
        if mod == ":t" then
            return path:match("([^/]+)$") or path
        end
        if mod == ":r" then
            return (path:gsub("%.[^%.]+$", ""))
        end
        return path
    end
    v.ui = v.ui or {}
    v.ui.input = function(_, cb)
        cb(input_value)
    end
    v.api.nvim_get_current_buf = function()
        return current_buf
    end
    v.api.nvim_buf_get_lines = function()
        return { "line1", "line2" }
    end
    v.api.nvim_command = function(cmd)
        cmds[#cmds + 1] = cmd
    end
    v.cmd = function(cmd)
            cmds[#cmds + 1] = cmd
        end
    v.notify = function(msg)
            notifications[#notifications + 1] = msg
        end
    v.tbl_deep_extend = function(_, base, user)
            local function merge(a, b)
                for k, v in pairs(b or {}) do
                    if type(v) == "table" and type(a[k]) == "table" then
                        merge(a[k], v)
                    else
                        a[k] = v
                    end
                end
            end
            local out = {}
            for k, v in pairs(base) do
                out[k] = v
            end
            merge(out, user or {})
            return out
        end
    v.split = function(str, sep)
            return split_plain(str, sep)
        end
    v.trim = function(str)
            return (str:gsub("^%s+", ""):gsub("%s+$", ""))
        end

    package.loaded["scretch"] = nil
    local mod = require("scretch")

    local ctx = {
        module = mod,
        cmds = cmds,
        notifications = notifications,
        fs = fs,
        files = files,
        set_input = function(v) input_value = v end,
        set_current_file = function(v) current_file = v end,
    }
    test_fn(ctx)
end

with_module(function(t)
    t.fs["/tmp/nvim-data/scretch/scretch_1.txt"] = { type = "file" }
    t.module.new()
    assert_eq(t.cmds[#t.cmds], "vsplit /tmp/nvim-data/scretch/scretch_2.txt", "new should pick next file number")
end)

with_module(function(t)
    t.set_input("daily.md")
    t.module.new_named()
    assert_eq(t.cmds[#t.cmds], "vsplit /tmp/nvim-data/scretch/daily.md", "new_named should open named file")
end)

with_module(function(t)
    t.fs["/tmp/nvim-data/scretch/a.txt"] = { type = "file", mtime = { sec = 10 } }
    t.fs["/tmp/nvim-data/scretch/b.txt"] = { type = "file", mtime = { sec = 20 } }
    t.set_current_file("/tmp/nvim-data/scretch/a.txt")
    t.module.last()
    assert_eq(t.cmds[#t.cmds], "vsplit /tmp/nvim-data/scretch/b.txt", "last should open most recent file")
end)

with_module(function(t)
    t.module.last()
    assert_truthy(#t.notifications >= 1, "last should notify when no file is present")
end)

with_module(function(t)
    local captured = nil
    package.loaded["fzf-lua"] = {
        files = function(opts)
            captured = opts
        end
    }
    t.module.setup({
        backend = "fzf-lua",
        use_project_dir = {
            template = false,
            template_project_dir = ".scretch/templates/",
        }
    })
    t.module.template_use_project_mode()
    t.module.edit_template()
    assert_truthy(captured ~= nil, "edit_template should call configured backend")
    assert_eq(captured.cwd, "/tmp/scretch-tests/.scretch/templates/", "project mode should force project template dir")
end)

with_module(function(t)
    t.set_input("")
    t.module.new_named()
    assert_eq(#t.cmds, 0, "new_named should no-op on empty input")
end)

with_module(function(t)
    t.fs["/tmp/nvim-data/scretch/a.txt"] = { type = "file", mtime = { sec = 10 } }
    t.fs["/tmp/nvim-data/scretch/b.txt"] = { type = "file", mtime = { sec = 20 } }
    local path = t.module._internal.get_most_recent_file("/tmp/nvim-data/scretch/")
    assert_eq(path, "/tmp/nvim-data/scretch/b.txt", "last file should be highest mtime")
end)

with_module(function(t)
    local lines = {
        "Title: {{ title }}",
        "Date: {{ date | format:YYYY/MM/dd }}",
        "Author: {{ author }}",
        "Upper: {{ title | uppercase }}",
    }
    t.module.setup({
        template_variables = {
            author = { source = "literal", value = "John Doe" },
        }
    })
    local rendered = t.module._internal.render_template_content(lines, "/tmp/template.md", "/tmp/notes/my-note.md")
    assert_eq(rendered[1], "Title: my-note", "title variable should use output filename")
    assert_truthy(rendered[2]:match("^Date: %d%d%d%d/%d%d/%d%d$"), "date format filter should apply")
    assert_eq(rendered[3], "Author: John Doe", "author literal source should apply")
    assert_eq(rendered[4], "Upper: MY-NOTE", "uppercase filter should apply")
end)

with_module(function(t)
    local lines = { "X={{ unknown }} Y={{ title | badfilter }}" }
    local rendered = t.module._internal.render_template_content(lines, "/tmp/template.md", "/tmp/notes/note.md")
    assert_eq(rendered[1], "X= Y=", "unknown values should resolve to empty")
    assert_truthy(#t.notifications >= 1, "should notify warnings")
end)

with_module(function(t)
    t.module.setup({
        template_variables = {
            custom = {
                project = function(ctx)
                    return ctx.cwd:match("([^/]+)$")
                end
            }
        }
    })
    local lines = { "Project: {{ project }}" }
    local rendered = t.module._internal.render_template_content(lines, "/tmp/template.md", "/tmp/notes/note.md")
    assert_eq(rendered[1], "Project: scretch-tests", "custom variable should render from ctx")
end)

with_module(function(t)
    local lines = { "No render {{ title }}" }
    t.module.setup({ template_variables = { enabled = false } })
    local rendered = t.module._internal.render_template_content(lines, "/tmp/template.md", "/tmp/notes/note.md")
    assert_eq(rendered[1], "No render {{ title }}", "rendering can be disabled globally")
end)
