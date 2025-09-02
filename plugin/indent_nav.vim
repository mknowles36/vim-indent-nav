" indent_nav.vim
" Author: Gemini
" Description: A Vim plugin to navigate between lines with the same or lower indentation level.

" Prevent the script from being loaded more than once
if exists("g:loaded_indent_nav")
    finish
endif
let g:loaded_indent_nav = 1

" --- Functions ---

" Function to find the indentation level of a given line number.
" @param lnum: The line number to check.
" @return: The indentation level of the line.
function! s:GetIndent(lnum)
    return indent(a:lnum)
endfunction

" Function to move to the next line with the same or lower indentation level.
function! SkipToNextIndentBlock()
    let current_line = line('.')
    let last_line = line('$')
    if current_line == last_line
        return
    endif

    let current_indent = s:GetIndent(current_line)
    let next_line = nextnonblank(current_line + 1)

    while next_line > 0 && next_line <= last_line
        if s:GetIndent(next_line) <= current_indent
            call cursor(next_line, 1)
            " Keep original column if possible, otherwise move to first non-whitespace
            normal! ^
            return
        endif
        let next_line = nextnonblank(next_line + 1)
    endwhile
endfunction

" Function to create a motion for an operator or extend a visual selection
" to cover the current indented block.
" @param is_visual: 1 if called from visual mode, 0 otherwise.
function! s:SelectIndentBlockMotion(is_visual)
    " Determine the starting line. For visual mode, it's the start of the selection ('<).
    " For operator-pending mode, it's the current cursor position. Using line("'<")
    " is unreliable for the first operation in a new buffer.
    let start_line = a:is_visual ? line("'<") : line('.')

    " If in operator-pending mode, we must start a visual selection so the
    " operator has something to act upon.
    if !a:is_visual
        normal! V
    endif

    let start_indent = s:GetIndent(start_line)
    " A negative indent means an invalid line number was found. Bail out.
    if start_indent < 0
        return
    endif
    let last_file_line = line('$')

    let end_line = start_line
    let check_line = start_line + 1

    " Find the end of the indented block
    while check_line <= last_file_line && s:GetIndent(check_line) > start_indent
        let end_line = check_line
        let check_line += 1
    endwhile

    " After the block, also select any trailing blank lines.
    while check_line <= last_file_line && getline(check_line) =~ '^\s*$'
        let end_line = check_line
        let check_line += 1
    endwhile

    " Move the cursor to the end of the block, extending the selection.
    if end_line > start_line
        if a:is_visual
            " Re-create the visual selection from its original start to the new end.
            " This is necessary because calling a function via ':' exits visual mode.
            execute "normal! " . start_line . "GV" . end_line . "G"
        else
            " For operator-pending mode, just moving the cursor is enough to define
            " the motion's boundary.
            call cursor(end_line, 1)
        endif
    endif
endfunction

" Function to move to the previous line with the same or lower indentation level.
function! SkipToPrevIndentBlock()
    let current_line = line('.')
    if current_line == 1
        return
    endif

    let current_indent = s:GetIndent(current_line)
    let prev_line = prevnonblank(current_line - 1)

    while prev_line > 0
        if s:GetIndent(prev_line) <= current_indent
            call cursor(prev_line, 1)
            " Keep original column if possible, otherwise move to first non-whitespace
            normal! ^
            return
        endif
        let prev_line = prevnonblank(prev_line - 1)
    endwhile
endfunction

" --- Mappings ---

" Map 'j' and 'k' to the new functions in normal mode.
" <silent> prevents the command from being echoed in the command line.
" noremap ensures that the mapping is not recursive.
nnoremap <silent> j :call SkipToNextIndentBlock()<CR>
nnoremap <silent> k :call SkipToPrevIndentBlock()<CR>

" Map 'j' in operator-pending and visual modes to select the current indented block.
" We use <SID> to ensure the script's context is not lost.
onoremap <silent> j :<C-U>call <SID>SelectIndentBlockMotion(0)<CR>
xnoremap <silent> j :<C-U>call <SID>SelectIndentBlockMotion(1)<CR>


" --- Commands (Optional) ---
" You could also expose these as commands if you like.
command! NextIndentBlock call SkipToNextIndentBlock()
command! PrevIndentBlock call SkipToPrevIndentBlock()
