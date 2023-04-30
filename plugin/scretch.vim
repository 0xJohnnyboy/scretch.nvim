" Title:        Scretch
" Description:  A plugin to create and manage scratch files.
" Maintainer:   Théo LAMBERT <https://github.com/Sonicfury>
if exists("g:loaded_scretch") | finish | endif
let g:loaded_scretch = 1

function! s:scratch_command(command)
  let parts = split(a:command, ' ')
  let cmd = parts[0]
  let args = parts[1:]
  execute 'lua require("scretch").' . cmd . '(' . join(map(args, 'v:val =~# "\\<\\d\\+\\>" ? v:val : "\\"" . substitute(v:val, "\\", "\\\\\\\\", "g") . "\\""'), ', ') . ')'
endfunction

command! -nargs=* Scretch call s:scratch_command(<q-args>)

command! -nargs=* -complete=customlist,s:scratch_commands Scretch call s:scratch_command(<f-args>)

function! s:scratch_commands(arglead, cmdline, cursorpos)
  let commands = ['new', 'new_named', 'last', 'search', 'grep', 'explore']
  return filter(commands, 'v:val =~ "^" . a:arglead')
endfunction

