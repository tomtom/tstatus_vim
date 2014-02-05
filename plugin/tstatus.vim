" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tstatus)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    154

if &cp || exists("g:loaded_tstatus")
    finish
endif
let g:loaded_tstatus = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:tstatus_timefmt')
    " A string for |strftime()|. If empty, don't display a time stamp in 
    " the status line. Example for |vimrc|: >
    "
    "   let g:tstatus_timefmt = '%d-%b-%Y %H:%M'
    let g:tstatus_timefmt = ''   "{{{2
endif


if !exists('g:tstatus_exprs')
    " A list of |eval()| expressions. E.g. >
    "
    "   call add(g:tstatus_exprs, 'mode()')
    let g:tstatus_exprs = []   "{{{2
endif


if !exists('g:tstatus_names')
    " A string or list of names that can be defined at startup for use 
    " with |:TStatusregister|.
    let g:tstatus_names = 'ai bin cole cpo et fdl fo js list paste sol sw ts tw wm enc fenc'    "{{{2
endif


if !exists('g:tstatus_colorscheme')
    " If empty, don't set the statusline color.
    " If a punctuation character, set the statusline color but assume 
    " the user has created the appropriate highlight definitions for the 
    " following highlight groups:
    "
    "   StatusLineNormal
    "   StatusLineInsert
    "   StatusLineVisual
    let g:tstatus_colorscheme = 'tstatus'   "{{{2
endif


if !exists('g:tstatus_rulerformat0')
    let g:tstatus_rulerformat0 = &rulerformat   "{{{2
endif


if !exists('g:tstatus_rulerformat1')
    let g:tstatus_rulerformat1 = '%-010.25(%lx%c%V %P%R%M%W%)'   "{{{2
endif


if !exists('g:tstatus_statusline0')
    let g:tstatus_statusline0 = &statusline   "{{{2
endif


if !exists('g:tstatus_statusline1')
    let g:tstatus_statusline1 = '%1*[%{winnr()}:%02n]%* %2t %(%M%R%H%W%k%) %=%{TStatusSummary()} %3*<%l,%c%V,%p%%>%*'   "{{{2
endif


let s:options = {}
let s:status_labels = {
            \ 'fdl': 'F%s', 
			\ 'ai': {'type': 'bool'},
			\ 'bin': {'type': 'bool'},
			\ 'et': {'type': 'bool'},
			\ 'js': {'type': 'bool'},
			\ 'list': {'type': 'bool'},
			\ 'paste': {'type': 'bool'},
			\ 'sol': {'type': 'bool'},
			\ }


function! s:Set(statussel) "{{{3
    let &statusline  = g:tstatus_statusline{a:statussel}
    let &rulerformat = g:tstatus_rulerformat{a:statussel}
    if a:statussel
        if !empty(g:tstatus_colorscheme) && g:tstatus_colorscheme =~ '\w'
            exec 'colorscheme' g:tstatus_colorscheme
        endif
    else
        hi clear StatusLine
    endif
endf


fun! s:Reset(options)
    if empty(a:options)
        let options = keys(s:options)
    else
        let options = a:options
    endif
    for name in options
        if name =~ '^\l:'
            exec 'let '. name .' = s:options[name]'
        else
            exec 'let &'. name .' = s:options[name]'
        endif
    endfor
endf


function! s:Register(options) "{{{3
    " echom "DBG Register" string(a:options)
    for opt in a:options
        " echom "DBG Register 0" opt
        if stridx(opt, '=') != -1
            let ml = matchlist(opt, '^\([^=]\+\)=\(.*\)$')
            let name = ml[1]
            let label = ml[2]
            " echom "DBG Register 1" name label
            if label == 'bool'
                let s:status_labels[name] = {'type': 'bool'}
            else
                let s:status_labels[name] = label
            endif
        else
            let name = opt
        endif
        " echom "DBG Register 2" name
        if !has_key(s:options, name)
            if name == 'cpo' || name == 'cpoptions'
                let s:options[name] = s:save_cpo
            elseif name =~ '^\l:'
                if exists(name)
                    exec 'let s:options[name] = '. name
                else
                    exec 'let s:options[name] = ""'
                endif
            else
                exec 'let s:options[name] = &'. name
            endif
        endif
    endfor
endf


let s:mode = mode()

function! s:SetHighlight() "{{{3
    let mode = mode()
    if mode != s:mode
        if mode =~? '[vs]'
            hi clear StatusLine
            hi link StatusLine StatusLineVisual
        elseif mode =~? '[irc]'
            hi clear StatusLine
            hi link StatusLine StatusLineInsert
        else
            hi clear StatusLine
            hi link StatusLine StatusLineNormal
        endif
        let s:mode = mode
    endif
    " return ' '. s:mode
endf


" :nodoc:
function! TStatusSummary(...)
    let opt = []

    if !empty(g:tstatus_colorscheme)
        call s:SetHighlight()
    endif

    for o in sort(keys(s:options))
        if o =~ '^\l:'
            if !exists(o)
                continue
            else
                exec 'let ov = '. o
            endif
        else
            exec 'let ov = &'.o
        endif
        if ov != s:options[o]
            let type = ''
            if has_key(s:status_labels, o)
                let ol = s:status_labels[o]
                if type(ol) == 3 && type(o) == 0
                    let lab  = get(ol, o, '')
                elseif type(ol) == 4
                    let type = get(ol, 'type', '')
                    let lab  = get(ol, 'label', '')
                else
                    let lab = ol
                endif
                unlet ol
            else
                let lab = o
            endif
            if type == 'bool'
                if empty(lab)
                    call add(opt, (ov ? '+' : '-') . o)
                else
                    call add(opt, lab)
                endif
            elseif stridx(lab, '%s') != -1
                call add(opt, printf(lab, ov))
            else
                call add(opt, lab .'='. ov)
            endif
        endif
        unlet ov
    endfor

    for eval in g:tstatus_exprs
        let val = eval(eval)
        if !empty(val)
            call add(opt, val)
        endif
    endfor

    call add(opt, '<'. &filetype .'/'. &fileformat .'>')

    if !empty(g:tstatus_timefmt)
        call add(opt, strftime(a:0 >= 1 ? a:1 : g:tstatus_timefmt))
    endif

    return join(opt)
endf


" Set or unset (with bang) 'statusline' and 'rulerformat'.
command! -bang TStatus call s:Set(empty("<bang>"))


" :display: :TStatusregister OPT1 OPT2 ...
" Register a set of vim |options| or variables that should be watched. 
" Changes will be displayed in the statusline.
"
" This also saves the option's value at the time you call this command 
" for use with |:TStatusreset|.
"
" See also |g:tstatus_names|.
command! -nargs=+ -bar TStatusregister call s:Register([<f-args>])


" :display: :TStatusreset [OPT1 OPT2 ...]
" Reset all or some options to the value saved at the time when calling 
" |:TStatusregister|.
command! -nargs=* -bar TStatusreset call s:Reset([<f-args>])


if !empty(g:tstatus_names)
    if type(g:tstatus_names) == 1
        call s:Register(split(g:tstatus_names, '\s\+'))
    elseif type(g:tstatus_names) == 3
        call s:Register(g:tstatus_names)
    else
        throw "TStatus: g:tstatus_names must be either a string or a list"
    endif
endif


if has('vim_starting')
    augroup TStatus
        autocmd!
        autocmd VimEnter * TStatus
    augroup END
else
    TStatus
endif


let &cpo = s:save_cpo
unlet s:save_cpo
