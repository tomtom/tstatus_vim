" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tstatus)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    227

if &cp || exists("g:loaded_tstatus")
    finish
endif
let g:loaded_tstatus = 2

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
    "
    " See also |g:tstatus_events|.
    let g:tstatus_names = 'ai aw bin bomb bt cole cpo et fenc fdl fo js list paste sol sw ts tw wm enc fenc'    "{{{2
endif


if !exists('g:tstatus_ignore')
    " A dictionary of NAME => |REGEXP| FOR IGNORED VALUES.
    let g:tstatus_ignore = {}   "{{{2
endif


if !exists('g:tstatus_events')
    " |autocmd-events| on which the options in |g:tstatus_names| will be 
    " compiled.
    " If "*", update the values on every update of the 'statusline'.
    let g:tstatus_events = 'FocusGained,FileType,SessionLoadPost,QuickFixCmdPost,EncodingChanged,BufEnter,CursorHold,CursorHoldI'   "{{{2
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
let s:events = {}
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


function! s:GetOptName(opt) "{{{3
    let opt = a:opt
    if stridx(opt, '=') != -1
        let ml = matchlist(opt, '^\([^=]\{-}\)=\(\w*\)$')
        if empty(ml)
            throw 'TStatus: Malformed argument: '. opt
        endif
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
    return name
endf


function! s:Register(options) "{{{3
    " echom "DBG Register" string(a:options)
    let ev = '*'
    for opt in a:options
        " echom "DBG Register 0" opt
        if opt =~ '^-'
            let ml = matchlist(opt, '^--\?\([^=]\+\)=\(.*\)$')
            if empty(ml)
                throw 'TStatus: Malformed argument: '. opt
            endif
            let name = ml[1]
            let label = ml[2]
            if name == 'event'
                let ev = label
            else
                throw 'TStatus: Unsupported argument: '. opt
            endif
            continue
        else
            let name = s:GetOptName(opt)
        endif
        " echom "DBG Register 2" name
        if !has_key(s:options, name)
            let cev = s:CleanEvent(ev)
            if !has_key(s:events, cev)
                let s:events[cev] = []
                if ev != '*'
                    exec 'autocmd TStatus' ev '* call s:PrepareBufferStatus('. string([ev]) .')'
                endif
            endif
            call add(s:events[cev], name)
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
    for [cev, opts] in items(s:events)
        if cev == '*'
            call s:GetStatus(opt, opts)
        elseif exists('b:tstatus_'. cev)
            call add(opt, b:tstatus_{cev})
        endif
    endfor
    call s:PrepareExprs(opt, g:tstatus_exprs)
    if exists('b:tstatus_exprs')
        call s:PrepareExprs(opt, b:tstatus_exprs)
    endif
    call add(opt, '<'. &filetype .'/'. &fileformat .'>')
    if !empty(g:tstatus_timefmt)
        call add(opt, strftime(a:0 >= 1 ? a:1 : g:tstatus_timefmt))
    endif
    return join(opt)
endf


function! s:PrepareExprs(opt, exprs) "{{{3
    for eval in a:exprs
        let val = eval(eval)
        if !empty(val)
            call add(a:opt, val)
        endif
    endfor
endf


function! s:PrepareBufferStatus(events) "{{{3
    for ev in a:events
        let cev = s:CleanEvent(ev)
        if has_key(s:events, cev)
            let opt = []
            call s:GetStatus(opt, s:events[cev])
            let b:tstatus_{cev} = join(opt)
        endif
    endfor
endf


function! s:CleanEvent(ev) "{{{3
    if a:ev == '*'
        return a:ev
    else
        return substitute(a:ev, '\W', '_', 'g')
    endif
endf


function! s:GetStatus(opt, opts) "{{{3
    for o in a:opts
        if o =~ '^\l:'
            if !exists(o)
                continue
            else
                exec 'let ov = '. o
            endif
        else
            exec 'let ov = &'.o
        endif
        if ov != s:options[o] && s:NotIgnoredStatus(o, ov)
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
                    call add(a:opt, (ov ? '+' : '-') . o)
                else
                    call add(a:opt, lab)
                endif
            elseif empty(lab)
                call add(a:opt, ov)
            elseif stridx(lab, '%s') != -1
                call add(a:opt, printf(lab, ov))
            else
                call add(a:opt, lab .'='. ov)
            endif
        endif
        unlet ov
    endfor
endf


function! s:NotIgnoredStatus(field, value) "{{{3
    let ignore = get(g:tstatus_ignore, a:field, '')
    if empty(ignore)
        return 1
    else
        return a:value !~ ignore
    endif
endf


" Set or unset (with bang) 'statusline' and 'rulerformat'.
command! -bang TStatus call s:Set(empty("<bang>"))


" :display: :TStatusregister [OPTIONS] OPT1[=LABEL1] OPT2[=LABEL2] ...
" Register a set of vim |options| or variables that should be watched. 
" Changes will be displayed in the statusline.
"
" This also saves the option's value at the time you call this command 
" for use with |:TStatusreset|.
"
" OPT can be any option or variable (with g:, b:, or w: prefix).
"
" LABEL can be either empty, a string, or a format string for |printf()|.
"
" OPTIONS can be:
"
"   --event=AUTOCOMMAND_EVENTS ... Update the following options only on 
"                                   these |autocommand-events|.
"
" See also |g:tstatus_names| and |g:tstatus_exprs|.
command! -nargs=+ -bar TStatusregister call s:Register([<f-args>])


" :display: :TStatusreset [OPT1 OPT2 ...]
" Reset all or some options to the value saved at the time when calling 
" |:TStatusregister|.
command! -nargs=* -bar TStatusreset call s:Reset([<f-args>])


augroup TStatus
    autocmd!
    autocmd User tstatus call s:PrepareBufferStatus(keys(s:events))
augroup END


if !empty(g:tstatus_names)
    if type(g:tstatus_names) == 1
        call s:Register(['--event='. g:tstatus_events] + split(g:tstatus_names, '\s\+'))
    elseif type(g:tstatus_names) == 3
        call s:Register(['--event='. g:tstatus_events] + g:tstatus_names)
    else
        throw "TStatus: g:tstatus_names must be either a string or a list"
    endif
endif


if has('vim_starting')
    autocmd TStatus VimEnter * TStatus
else
    TStatus
endif


let &cpo = s:save_cpo
unlet s:save_cpo
