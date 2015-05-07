" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tstatus)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    244

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
    "
    " Users should use |:TStatusregister| to register values for the 
    " status line. Users might have to call |TStatusForceUpdate()| in 
    " order to properly update expressions listed in this variable.
    let g:tstatus_exprs = []   "{{{2
endif


if !exists('g:tstatus_names')
    " A string or list of names that can be defined at startup for use 
    " with |:TStatusregister|.
    "
    " See also |g:tstatus_events|.
    let g:tstatus_names = 'ai aw bin bomb bt cole cpo et fenc fdl ff fo js list paste sol sw ts tw wm enc fenc'    "{{{2
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
    let g:tstatus_statusline1 = '%1*%{winnr()}:%02n %* %2t %(%M%R%H%W%k%a%) %=%{TStatusSummary()} %y %1* %l,%c%V,%p%%'   "{{{2
endif


let s:options = {}
let s:events = {}
let s:opt_def = {
            \ 'fdl': {'label': 'F%s'},
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
        " if name =~ '?$'
        "     let name = substitute(name, '?$', '', '')
        "     let nopts = get(s:opt_def, name, {})
        "     if !has_key(nopts, 'type')
        "         let nopts.type = 'bool'
        "         let s:opt_def[name] = nopts
        "     endif
        " endif
        " echom "DBG Register 1" name label
    else
        let name = opt
        let label = ''
    endif
    call s:SetOptDef(name, name)
    return name
endf


function! s:SetOptDef(name, label) abort "{{{3
    let opt = get(s:opt_def, a:name, {})
    if a:label == 'bool'
        let opt.type = 'bool'
        let opt.label = '%s'. a:label
    elseif stridx(a:label, '%s') != -1
        let opt.label = a:label
    elseif empty(a:label)
        let opt.label = 'label': '%s'
    elseif get(opt, 'type', '') ==# 'bool'
        let opt.label = '%s'. a:label
    else
        let opt.label = a:label .'=%s'
    endif
    let s:opt_def[a:name] = opt
endf


function! s:ParseArgs(args) abort "{{{3
    let opts = {}
    for iopt in range(len(a:args))
        let opt = a:args[iopt]
        " echom "DBG Register 0" opt
        if opt =~ '^-'
            let ml = matchlist(opt, '^--\?\([^=]\+\)=\(.*\)$')
            if empty(ml)
                throw 'TStatus: Malformed argument: '. opt
            endif
            let name = ml[1]
            let label = ml[2]
            let opts[name] = label
        else
            break
        endif
    endfor
    let args = a:args[iopt : -1]
    return [opts, args]
endf


function! s:RegisterExpr(args) abort "{{{3
    let [opts, args] = s:ParseArgs(a:args)
    let [label; expr] = args
    let exprs = join(expr)
    " echom "DBG RegisterExpr" string(opts) string(label) string(exprs)
    call s:SetOptDef(exprs, label)
    let ev = get(opts, 'event', '*')
    call s:EnsureEvent(ev, exprs)
endf


function! s:Register(args) "{{{3
    " echom "DBG Register" string(a:args)
    let [opts, args] = s:ParseArgs(a:args)
    let ev = get(opts, 'event', '*')
    for name in args
        " echom "DBG Register 2" name
        call s:RegisterName(ev, s:GetOptName(name))
    endfor
endf


function! s:EnsureEvent(event, name) abort "{{{3
    for cev0 in split(a:event, ',')
        let cev = s:CleanEvent(cev0)
        if !has_key(s:events, cev)
            let s:events[cev] = []
            if cev != '*'
                exec 'autocmd TStatus' cev '* call s:PrepareBufferStatus('. string([cev]) .')'
            endif
        endif
        call add(s:events[cev], a:name)
    endfor
endf


function! s:RegisterName(event, name) abort "{{{3
    if !has_key(s:options, a:name)
        call s:EnsureEvent(a:event, a:name)
        if a:name == 'cpo' || a:name == 'cpoptions'
            let s:options[a:name] = s:save_cpo
        elseif a:name =~ '^\l:'
            if exists(a:name)
                exec 'let s:options[a:name] = '. a:name
            else
                exec 'let s:options[a:name] = ""'
            endif
        elseif exists('&'. a:name)
            exec 'let s:options[a:name] = &'. a:name
        endif
    endif
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


function! s:GetStatusCache() abort "{{{3
    if !exists('b:tstatus_cache')
        let b:tstatus_cache = {}
    endif
    return b:tstatus_cache
endf


function! s:GetStatusAsList() abort "{{{3
    return sort(values(s:GetStatusCache()), 1)
endf


function! TStatusForceUpdate() abort "{{{3
    " echom 'DBG TStatusForceUpdate'
    unlet! b:tstatus
endf


" :nodoc:
function! TStatusSummary(...)
    if !empty(g:tstatus_colorscheme)
        call s:SetHighlight()
    endif
    if !exists('b:tstatus')
        for [cev, opts] in items(s:events)
            if cev == '*'
                call s:FillStatus(opts)
            endif
        endfor
        let opt = s:GetStatusAsList()
        call s:PrepareExprs(opt, g:tstatus_exprs)
        if exists('b:tstatus_exprs')
            call s:PrepareExprs(opt, b:tstatus_exprs)
        endif
        if !empty(g:tstatus_timefmt)
            call add(opt, strftime(a:0 >= 1 ? a:1 : g:tstatus_timefmt))
        endif
        let b:tstatus = join(opt)
        " echom "DBG TStatusSummary" b:tstatus
    endif
    return b:tstatus
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
    if !empty(a:events)
        for ev in a:events
            let cev = s:CleanEvent(ev)
            if has_key(s:events, cev)
                call s:FillStatus(s:events[cev])
            endif
        endfor
    endif
endf


function! s:CleanEvent(ev) "{{{3
    if a:ev == '*'
        return a:ev
    else
        return substitute(a:ev, '\W', '_', 'g')
    endif
endf


function! s:FillStatus(opts) "{{{3
    " echom "DBG FillStatus" strftime("%c") string(a:opts)
    let status = s:GetStatusCache()
    let must_update = 0
    for o in a:opts
        if o =~ '^\l:'
            if !exists(o)
                continue
            else
                exec 'let ov = '. o
            endif
        elseif exists('&'. o)
            exec 'let ov = &'.o
        else
            exec 'let ov = '.o
        endif
        if ov != get(s:options, o, '') && s:NotIgnoredStatus(o, ov)
            " if type(ov) == 1 && ov == ''
            "     if has_key(status, o)
            "         call remove(status, o)
            "         let must_update = 1
            "     endif
            " else
                if has_key(s:opt_def, o)
                    let ol = s:opt_def[o]
                    let type = get(ol, 'type', '')
                    let lab  = get(ol, 'label', '%s')
                else
                    let type = ''
                    let lab = o
                endif
                if type == 'bool'
                    let text = printf(lab, ov ? '+' : '-')
                else
                    let text = printf(lab, ov)
                endif
                if get(status, o, '') !=# text
                    let status[o] = text
                    let must_update = 1
                endif
            " endif
        endif
        unlet ov
    endfor
    if must_update
        call TStatusForceUpdate()
    endif
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
" LABEL can be either empty, a string, or a format string for 
" |printf()|. If LABEL is 'bool', the option is treated as a boolean 
" option/variable.
"
" OPTIONS can be:
"
"   --event=AUTOCOMMAND_EVENTS ... Update the following options only on 
"                                   these |autocommand-events|.
"
" See also |g:tstatus_names| and |g:tstatus_exprs|.
command! -nargs=+ -bar TStatusregister call s:Register([<f-args>])


" :display: :TStatusregister1 [OPTIONS] LABEL EXPRESSION
" Register one labeled vim expression.
command! -nargs=+ -bar TStatusregister1 call s:RegisterExpr([<f-args>])


" :display: :TStatusreset [OPT1 OPT2 ...]
" Reset all or some options to the value saved at the time when calling 
" |:TStatusregister|.
command! -nargs=* -bar TStatusreset call s:Reset([<f-args>])


augroup TStatus
    autocmd!
    autocmd User tstatus call s:PrepareBufferStatus(keys(s:events))
    autocmd FileType * call TStatusForceUpdate()
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
