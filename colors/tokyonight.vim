vim9script
# tokyonight - Vim9 port of folke/tokyonight.nvim
# Default entry: honours g:tokyonight_style, falling back to the light style
# (g:tokyonight_light_style) when 'background' is "light".
#
#   let g:tokyonight_style = 'storm'   " storm | night | moon | day
#   colorscheme tokyonight

import autoload 'tokyonight.vim' as tn

var style = get(g:, 'tokyonight_style', 'moon')
if &background ==# 'light' && get(g:, 'tokyonight_style', '') ==# ''
  style = get(g:, 'tokyonight_light_style', 'day')
endif

tn.Setup(style, 'tokyonight')
