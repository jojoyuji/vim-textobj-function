" Text objects for Python
" Version 0.4.1
" Copyright (C) 2013 Brian Smyth <http://bsmyth.net>
" License: So-called MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}



let s:save_cpo = &cpo
set cpo&vim

if !exists('g:textobj_function_python_select')
  function! g:textobj_function_python_select(object_type)
    return s:select_{a:object_type}()
  endfunction

  function! s:select_a()
    return s:python_select_a('def')
  endfunction


  function! s:select_i()
    return s:python_select_i('def')
  endfunction


  function! s:move_cursor_to_starting_line()
    " Start at a nonblank line
    let l:cur_pos = getpos('.')
    let l:cur_line = getline('.')
    if l:cur_line =~# '^\s*$'
      call cursor(prevnonblank(l:cur_pos[1]), 0)
    endif
  endfunction

  function! s:find_defn_line(kwd)
    " Find the defn line
    let l:cur_pos = getpos('.')
    let l:cur_line = getline('.')
    if l:cur_line =~# '^\s*'.a:kwd.' '
      let l:defn_pos = l:cur_pos
    else
      let l:cur_indent = indent(l:cur_pos[1])
      while 1
	if search('^\s*'.a:kwd.' ', 'bW')
	  let l:defn_pos = getpos('.')
	  let l:defn_indent = indent(l:defn_pos[1])
	  if l:defn_indent >= l:cur_indent
	    " This is a defn at the same level or deeper, keep searching
	    continue
	  else
	    " Found a defn, make sure there aren't any statements at a
	    " shallower indent level in between
	    for l:l in range(l:defn_pos[1] + 1, l:cur_pos[1])
	      if getline(l:l) !~# '^\s*$' && indent(l:l) < l:defn_indent
		throw "defn-not-found"
	      endif
	    endfor
	    break
	  endif
	else
	  " We didn't find a suitable defn
	  throw "defn-not-found"
	endif
      endwhile
    endif
    call cursor(l:cur_pos[1], l:cur_pos[2])
    return l:defn_pos
  endfunction

  function! s:find_last_line(kwd, defn_pos, indent_level)
    " Find the last line of the block at given indent level
    let l:cur_pos = getpos('.')
    let l:end_pos = l:cur_pos
    while 1
      " Is this a one-liner?
      if getline('.') =~# '^\s*'.a:kwd.'\[^:\]\+:\s*\[^#\]'
	return a:defn_pos
      endif
      " This isn't a one-liner, so skip the def line
      if line('.') == a:defn_pos[1]
	normal! j
	continue
      endif
      if getline('.') !~# '^\s*$'
	if indent('.') > a:indent_level
	  let l:end_pos = getpos('.')
	else
	  break
	endif
      endif
      if line('.') == line('$')
	break
      else
	normal! j
      endif
    endwhile
    call cursor(l:cur_pos[1], l:cur_pos[2])
    return l:end_pos
  endfunction

  function! s:python_select_a(kwd)
    call s:move_cursor_to_starting_line()

    try
      let l:defn_pos = s:find_defn_line(a:kwd)
      let l:defn_indent_level = indent(l:defn_pos[1])
    catch /defn-not-found/
      return 0
    endtry

    let l:end_pos = s:find_last_line(a:kwd, l:defn_pos, l:defn_indent_level)

    return ['V', l:defn_pos, l:end_pos]
  endfunction

  function! s:python_select_i(kwd)
    let l:a_pos = s:python_select_a(a:kwd)
    if type(l:a_pos) != type([])
      return 0
    else
      if l:a_pos[1][1] == l:a_pos[2][1]
	" This is a one-liner, treat it like af
	" TODO Maybe change this to a 'v'-mode selection and only get the
	" statement from the one-liner?
	return l:a_pos
      endif
      " Put the cursor on the def line
      call cursor(l:a_pos[1][1], l:a_pos[1][2])
      " Get to the closing paren, then go down a line
      normal! ^f(%j0
      let l:start_pos = getpos('.')
      return ['V', l:start_pos, l:a_pos[2]]
    endif
  endfunction
endif


let b:textobj_function_select = function('g:textobj_function_python_select')


nnoremap <buffer> <silent> ]pc :call search('^\s*\zsclass ', 'W')<CR>
nnoremap <buffer> <silent> [pc :call search('^\s*\zsclass ', 'bW')<CR>
nnoremap <buffer> <silent> ]pf :call search('^\s*\zsdef ', 'W')<CR>
nnoremap <buffer> <silent> [pf :call search('^\s*\zsdef ', 'bW')<CR>
onoremap <buffer> <silent> ]pc :call search('^\s*\zsclass ', 'W')<CR>
onoremap <buffer> <silent> [pc :call search('^\s*\zsclass ', 'bW')<CR>
onoremap <buffer> <silent> ]pf :call search('^\s*\zsdef ', 'W')<CR>
onoremap <buffer> <silent> [pf :call search('^\s*\zsdef ', 'bW')<CR>


if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= ' | '
else
  let b:undo_ftplugin = ''
endif
let b:undo_ftplugin .= 'unlet b:textobj_function_select'


let &cpo = s:save_cpo
unlet s:save_cpo

