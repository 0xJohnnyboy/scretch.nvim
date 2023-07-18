-- Title:        Scretch
-- Description:  A plugin to create and manage scratch files.
-- Maintainer:   Théo LAMBERT <https://github.com/Sonicfury>

local function ScretchCompletion(lead, cmd, cursor)
    local valid_args = vim.tbl_keys(require('scretch'))
    valid_args = vim.tbl_filter(function(a)
        return a ~= "setup"
    end, valid_args)
    local l = string.len(lead)
    local filtered_args = vim.tbl_filter(function(v)
        return v:sub(1, l) == lead
    end, valid_args)
    if not vim.tbl_isempty(filtered_args) then
        return filtered_args
    end
    return valid_args
end

vim.api.nvim_create_user_command("Scretch", function(fargs)
    if vim.tbl_isempty(fargs.fargs) then
        fargs.fargs[1] = "new"
    end
    require('scretch')[fargs.fargs[1]]()
end, { nargs = '*', complete = ScretchCompletion, })
