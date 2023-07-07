" compiler.vim - C Compiler Plugin

if exists("g:did_c_compiler")
	finish
endif

let g:did_c_compiler = 1

" When click F5 compile with gcc
nnoremap <buffer> <F5> :call Compile()<CR><CR><CR>

function! Compile()
 	let l:filename = expand('%')
	let l:error_file = l:filename . '.err'
	execute '!' . 'gcc ' . l:filename . ' 2> ' . l:error_file 
	let l:extract_errors = system('findstr "' . l:filename . ':[0-9]" ' . l:error_file)
        call writefile(split(l:extract_errors, "\n"), l:error_file)
	call ReadFromFile(l:error_file) 
endfunction

function! ReadFromFile(error_file)
	let file_size = getfsize(a:error_file)
	if file_size != 0
		let l:file_lines = readfile(a:error_file)
		for error in l:file_lines 
			let l:error_content = matchstr(error, 'error: \zs.*\|warning: \zs.*')
			if len(l:error_content) != 0
				let l:line_number = matchstr(error, ':\zs\(\d\+\)\ze:')
				let l:line_content = getline(str2nr(l:line_number))
				if error =~# 'error:'
					call CreatePopup('error', l:error_content, l:line_number, l:line_content)
				elseif error =~# 'warning:'
					call CreatePopup('warning', l:error_content, l:line_number, l:line_content)
				endif
			endif
		endfor
	else
		call CreatePopup('complete', 'No errors found!', '1', '')
	endif
	call delete(a:error_file)
	call timer_start(7000, { -> execute('call CloseAllPopups()')})
endfunction

function! CreatePopup(type, error_content, line_number, line_content)
	if a:type == 'error'
		highlight popup_color_red ctermbg=red guibg=red ctermfg=black guifg=black
		call popup_create(a:error_content, {'line': str2nr(a:line_number), 'col': (strdisplaywidth(a:line_content) + 5), 'highlight': 'popup_color_red'})
	elseif a:type == 'warning'
		highlight popup_color_yellow ctermbg=yellow guibg=yellow ctermfg=black guifg=black
		call popup_create(a:error_content, {'line': str2nr(a:line_number), 'col': (strdisplaywidth(a:line_content) + 5), 'highlight': 'popup_color_yellow'})
	elseif a:type == 'complete'
		highlight popup_color_green ctermbg=green guibg=green ctermfg=black guifg=black
		call popup_create(a:error_content, {'line': str2nr(a:line_number), 'col': (strdisplaywidth(getline(a:line_number)) + 5), 'highlight': 'popup_color_green'})
	endif
endfunction

function! CloseAllPopups()
  	let popup_list = popup_list()
  	for popup_id in popup_list
    		call popup_close(popup_id)
  	endfor
endfunction

