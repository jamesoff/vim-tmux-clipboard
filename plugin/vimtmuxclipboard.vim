
function! s:TmuxBufferName()
	let l:list = systemlist('tmux list-buffers -F"#{buffer_name}"')
	if len(l:list)==0
		return ""
	else
		return l:list[0]
	endif
endfunction

function! s:TmuxBuffer()
	if has('nvim')
		let s:job1 = jobstart(['tmux', 'show-buffer'], {
					\ 'on_stdout': function('s:JobHandler'),
					\ 'on_exit': function('s:JobHandler'),
					\ 'stdout_buffered': v:true } )
	else
		let @" = system('tmux show-buffer')
	endif
endfunction

function! s:JobHandler(job_id, data, event) dict
	if a:event == 'stdout'
		let s:chunks = join(a:data, "\n")
	endif
	if a:event == 'exit'
		if a:data == 0
			let @" = s:chunks
		endif
	endif
endfunction


function! s:Enable()

	if $TMUX==''
		" not in tmux session
		return
	endif

	let s:lastbname=""

	" if support TextYankPost
	if exists('##TextYankPost')==1
		" @"
		augroup vimtmuxclipboard
			autocmd!
			autocmd FocusLost * let s:lastbname=s:TmuxBufferName()
			autocmd	FocusGained   * if s:lastbname!=s:TmuxBufferName() | call s:TmuxBuffer() | endif
			autocmd TextYankPost * silent! call system('tmux loadb -',join(v:event["regcontents"],"\n"))
		augroup END
		call s:TmuxBuffer()
	else
		" vim doesn't support TextYankPost event
		" This is a workaround for vim
		augroup vimtmuxclipboard
			autocmd!
			autocmd FocusLost     *  silent! call system('tmux loadb -',@")
			autocmd	FocusGained   *  let @" = s:TmuxBuffer()
		augroup END
		let @" = s:TmuxBuffer()
	endif

endfunction

call s:Enable()

	" " workaround for this bug
	" if shellescape("\n")=="'\\\n'"
	" 	let l:s=substitute(l:s,'\\\n',"\n","g")
	" 	let g:tmp_s=substitute(l:s,'\\\n',"\n","g")
	" 	");
	" 	let g:tmp_cmd='tmux set-buffer ' . l:s
	" endif
	" silent! call system('tmux loadb -',l:s)

