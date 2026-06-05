" -----------------------------------------------------------------------------
" File: autoload/lightline/colorscheme/tokyonight.vim
" Description: Tokyo Night (storm) colorscheme for lightline.vim
" Source: https://github.com/folke/tokyonight.nvim
" Note: native Vimscript port; palette mirrors the upstream lightline theme.
" -----------------------------------------------------------------------------

" Each color is [ guicolor, ctermcolor ]. cterm values are the nearest xterm-256.
let s:bg            = [ '#24283b', 236 ]
let s:bg_statusline = [ '#1f2335', 235 ]
let s:bg_highlight  = [ '#292e42', 236 ]
let s:fg            = [ '#c0caf5', 153 ]
let s:fg_gutter     = [ '#3b4261', 239 ]
let s:dark3         = [ '#545c7e', 60  ]
let s:black         = [ '#1d202f', 235 ]
let s:blue          = [ '#7aa2f7', 111 ]
let s:green         = [ '#9ece6a', 149 ]
let s:magenta       = [ '#bb9af7', 141 ]
let s:red           = [ '#f7768e', 210 ]
let s:error         = [ '#db4b4b', 167 ]
let s:warning       = [ '#e0af68', 179 ]

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

" normal mode
let s:p.normal.left    = [ [ s:black, s:blue ], [ s:blue, s:fg_gutter ] ]
let s:p.normal.middle  = [ [ s:fg, s:bg_statusline ] ]
let s:p.normal.right   = [ [ s:black, s:blue ], [ s:blue, s:fg_gutter ] ]
let s:p.normal.error   = [ [ s:black, s:error ] ]
let s:p.normal.warning = [ [ s:black, s:warning ] ]

" insert / visual / replace (only the accent segment changes upstream)
let s:p.insert.left    = [ [ s:black, s:green ], [ s:blue, s:bg ] ]
let s:p.visual.left    = [ [ s:black, s:magenta ], [ s:blue, s:bg ] ]
let s:p.replace.left   = [ [ s:black, s:red ], [ s:blue, s:bg ] ]

" inactive windows
let s:p.inactive.left   = [ [ s:blue, s:bg_statusline ], [ s:dark3, s:bg ] ]
let s:p.inactive.middle = [ [ s:fg_gutter, s:bg_statusline ] ]
let s:p.inactive.right  = [ [ s:fg_gutter, s:bg_statusline ], [ s:dark3, s:bg ] ]

" tabline
let s:p.tabline.left   = [ [ s:dark3, s:bg_highlight ], [ s:dark3, s:bg ] ]
let s:p.tabline.middle = [ [ s:fg_gutter, s:bg_statusline ] ]
let s:p.tabline.right  = [ [ s:fg_gutter, s:bg_statusline ], [ s:dark3, s:bg ] ]
let s:p.tabline.tabsel = [ [ s:blue, s:fg_gutter ], [ s:dark3, s:bg ] ]

let g:lightline#colorscheme#tokyonight#palette = lightline#colorscheme#flatten(s:p)
