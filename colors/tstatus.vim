" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Revision:    21


if &background == 'dark'

    hi StatusLineNormal     gui=Bold            guibg=#8db6cd    guifg=#000000
    hi StatusLineInsert     gui=Bold            guibg=#cacd8d    guifg=#000000
    hi StatusLineVisual     gui=Bold            guibg=#cd8d8e    guifg=#000000
    hi StatusLineNC         gui=None            guibg=#617c8d    guifg=#1a1a1a
    hi default link StatusLine StatusLineNormal

else

    hi StatusLineNormal     gui=Bold            guibg=#8db6cd    guifg=#000000
    hi StatusLineInsert     gui=Bold            guibg=#cacd8d    guifg=#000000
    hi StatusLineVisual     gui=Bold            guibg=#cd8d8e    guifg=#000000
    hi StatusLineNC         gui=None            guibg=#a3d2ed    guifg=#1a1a1a

endif

hi default link StatusLine StatusLineNormal


