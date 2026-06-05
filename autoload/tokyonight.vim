vim9script
# -----------------------------------------------------------------------------
# File: autoload/tokyonight.vim
# Description: Vim9 port of folke's tokyonight.nvim colour scheme.
# Source:      https://github.com/folke/tokyonight.nvim
# Styles:      storm, night, moon (dark) and day (light)
# Requires:    Vim 9.0+ with 'termguicolors' (true colour terminal or GUI)
# -----------------------------------------------------------------------------

# Palettes --------------------------------------------------------------------
# The storm / night / moon palettes are copied verbatim from the upstream Lua
# sources. The "day" palette is derived upstream by inverting the "night"
# palette in HSLuv space (with day_brightness = 0.3); since HSLuv is far too
# heavy to evaluate at runtime in Vimscript, the result is pre-computed here.

const palettes: dict<dict<string>> = {
  storm: {
    bg: '#24283b', bg_dark: '#1f2335', bg_dark1: '#1b1e2d', bg_highlight: '#292e42',
    blue: '#7aa2f7', blue0: '#3d59a1', blue1: '#2ac3de', blue2: '#0db9d7',
    blue5: '#89ddff', blue6: '#b4f9f8', blue7: '#394b70', comment: '#565f89',
    cyan: '#7dcfff', dark3: '#545c7e', dark5: '#737aa2', fg: '#c0caf5',
    fg_dark: '#a9b1d6', fg_gutter: '#3b4261', green: '#9ece6a', green1: '#73daca',
    green2: '#41a6b5', magenta: '#bb9af7', magenta2: '#ff007c', orange: '#ff9e64',
    purple: '#9d7cd8', red: '#f7768e', red1: '#db4b4b', teal: '#1abc9c',
    terminal_black: '#414868', yellow: '#e0af68',
    git_add: '#449dab', git_change: '#6183bb', git_delete: '#914c54',
  },
  night: {
    bg: '#1a1b26', bg_dark: '#16161e', bg_dark1: '#0c0e14', bg_highlight: '#292e42',
    blue: '#7aa2f7', blue0: '#3d59a1', blue1: '#2ac3de', blue2: '#0db9d7',
    blue5: '#89ddff', blue6: '#b4f9f8', blue7: '#394b70', comment: '#565f89',
    cyan: '#7dcfff', dark3: '#545c7e', dark5: '#737aa2', fg: '#c0caf5',
    fg_dark: '#a9b1d6', fg_gutter: '#3b4261', green: '#9ece6a', green1: '#73daca',
    green2: '#41a6b5', magenta: '#bb9af7', magenta2: '#ff007c', orange: '#ff9e64',
    purple: '#9d7cd8', red: '#f7768e', red1: '#db4b4b', teal: '#1abc9c',
    terminal_black: '#414868', yellow: '#e0af68',
    git_add: '#449dab', git_change: '#6183bb', git_delete: '#914c54',
  },
  moon: {
    bg: '#222436', bg_dark: '#1e2030', bg_dark1: '#191b29', bg_highlight: '#2f334d',
    blue: '#82aaff', blue0: '#3e68d7', blue1: '#65bcff', blue2: '#0db9d7',
    blue5: '#89ddff', blue6: '#b4f9f8', blue7: '#394b70', comment: '#636da6',
    cyan: '#86e1fc', dark3: '#545c7e', dark5: '#737aa2', fg: '#c8d3f5',
    fg_dark: '#828bb8', fg_gutter: '#3b4261', green: '#c3e88d', green1: '#4fd6be',
    green2: '#41a6b5', magenta: '#c099ff', magenta2: '#ff007c', orange: '#ff966c',
    purple: '#fca7ea', red: '#ff757f', red1: '#c53b53', teal: '#4fd6be',
    terminal_black: '#444a73', yellow: '#ffc777',
    git_add: '#b8db87', git_change: '#7ca1f2', git_delete: '#e26a75',
  },
  day: {
    bg: '#e1e2e7', bg_dark: '#d0d5e3', bg_dark1: '#c1c9df', bg_highlight: '#c4c8da',
    blue: '#2e7de9', blue0: '#7890dd', blue1: '#188092', blue2: '#07879d',
    blue5: '#006a83', blue6: '#2e5857', blue7: '#92a6d5', comment: '#848cb5',
    cyan: '#007197', dark3: '#8990b3', dark5: '#68709a', fg: '#3760bf',
    fg_dark: '#6172b0', fg_gutter: '#a8aecb', green: '#587539', green1: '#387068',
    green2: '#38919f', magenta: '#9854f1', magenta2: '#d20065', orange: '#b15c00',
    purple: '#7847bd', red: '#f52a65', red1: '#c64343', teal: '#118c74',
    terminal_black: '#a1a6c5', yellow: '#8c6c3e',
    git_add: '#4197a4', git_change: '#506d9c', git_delete: '#c47981',
  },
}

# Brightened terminal colours (upstream Util.brighten in HSLuv, pre-computed).
const bright: dict<dict<string>> = {
  storm: {red: '#ff899d', green: '#9fe044', yellow: '#faba4a', blue: '#8db0ff', magenta: '#c7a9ff', cyan: '#a4daff'},
  night: {red: '#ff899d', green: '#9fe044', yellow: '#faba4a', blue: '#8db0ff', magenta: '#c7a9ff', cyan: '#a4daff'},
  moon:  {red: '#ff8d94', green: '#c7fb6d', yellow: '#ffd8ab', blue: '#9ab8ff', magenta: '#caabff', cyan: '#b2ebff'},
  day:   {red: '#ff4774', green: '#5c8524', yellow: '#a27629', blue: '#358aff', magenta: '#a463ff', cyan: '#007ea8'},
}

# Colour blending -------------------------------------------------------------
# bg_color / fg_color hold the active background / foreground, used as the
# default blend endpoints (mirrors Util.blend_bg / Util.blend_fg).
var bg_color = '#000000'
var fg_color = '#ffffff'

def Rgb(hex: string): list<number>
  return [str2nr(hex[1 : 2], 16), str2nr(hex[3 : 4], 16), str2nr(hex[5 : 6], 16)]
enddef

# Blend foreground over background. alpha 0.0 => bg, 1.0 => fg.
def Blend(fg: string, alpha: float, bg: string): string
  var f = Rgb(fg)
  var b = Rgb(bg)
  var Ch = (i: number): number => {
    var v = float2nr(floor(alpha * f[i] + (1.0 - alpha) * b[i] + 0.5))
    return max([0, min([255, v])])
  }
  return printf('#%02x%02x%02x', Ch(0), Ch(1), Ch(2))
enddef

def BlendBg(hex: string, alpha: float): string
  return Blend(hex, alpha, bg_color)
enddef

def BlendFg(hex: string, alpha: float): string
  return Blend(hex, alpha, fg_color)
enddef

# Highlight applier -----------------------------------------------------------
# A string spec is treated as a link; a dict spec carries fg/bg/sp and the
# usual attribute flags (bold, italic, underline, undercurl, ...).
const attr_flags = ['bold', 'italic', 'underline', 'undercurl', 'underdouble',
  'underdotted', 'underdashed', 'strikethrough', 'reverse', 'standout', 'nocombine']

# Tree-sitter / LSP group names contain '@', which is valid for :highlight (the
# groups are created and work) but makes Vim9's :execute emit a harmless W18
# warning. Such commands are run with :silent! so they don't spam messages;
# standard group names are run normally so genuine errors still surface.
def Run(cmd: string)
  if stridx(cmd, '@') >= 0
    silent! execute cmd
  else
    execute cmd
  endif
enddef

def Hl(group: string, spec: any)
  if type(spec) == v:t_string
    Run('highlight! link ' .. group .. ' ' .. spec)
    return
  endif
  var d: dict<any> = spec
  var args = ['highlight', group]
  # Always emit fg/bg (defaulting to NONE) and reset cterm/term, so built-in
  # default attributes — e.g. MatchParen's guibg=DarkCyan or term=reverse —
  # never leak through after 'highlight clear'.
  args->add('guifg=' .. get(d, 'fg', 'NONE'))
  args->add('guibg=' .. get(d, 'bg', 'NONE'))
  if has_key(d, 'sp') | args->add('guisp=' .. d.sp) | endif
  var attrs: list<string> = []
  for a in attr_flags
    if get(d, a, false)
      attrs->add(a)
    endif
  endfor
  var gui = empty(attrs) ? 'NONE' : join(attrs, ',')
  args->add('gui=' .. gui)
  args->add('cterm=' .. gui)
  args->add('term=NONE')
  args->add('ctermfg=NONE')
  args->add('ctermbg=NONE')
  Run(join(args, ' '))
enddef

# Terminal (:terminal) ANSI colours -------------------------------------------
def Terminal(c: dict<string>, style: string)
  if !has('terminal') && !has('nvim')
    return
  endif
  var b = bright[style]
  g:terminal_ansi_colors = [
    c.black, c.red, c.green, c.yellow,
    c.blue, c.magenta, c.cyan, c.fg_dark,
    c.terminal_black, b.red, b.green, b.yellow,
    b.blue, b.magenta, b.cyan, c.fg,
  ]
  # Neovim uses g:terminal_color_0..15 instead of g:terminal_ansi_colors.
  if has('nvim')
    for i in range(16)
      execute printf('g:terminal_color_%d = %s', i, string(g:terminal_ansi_colors[i]))
    endfor
  endif
enddef

# Main entry ------------------------------------------------------------------
export def Setup(style_arg: string = '', name: string = '')
  var style = has_key(palettes, style_arg) ? style_arg : 'moon'

  # Keep 'background' consistent with the chosen style before clearing.
  var want_bg = style == 'day' ? 'light' : 'dark'
  if &background != want_bg
    &background = want_bg
  endif

  highlight clear
  if exists('syntax_on')
    syntax reset
  endif
  g:colors_name = !empty(name) ? name : 'tokyonight-' .. style

  if has('termguicolors')
    set termguicolors
  endif

  # Options (mirror tokyonight.nvim config) -----------------------------------
  var transparent   = get(g:, 'tokyonight_transparent', 0)
  var dim_inactive  = get(g:, 'tokyonight_dim_inactive', 0)
  var term_colors   = get(g:, 'tokyonight_terminal_colors', 1)
  var st_comments   = get(g:, 'tokyonight_italic_comments', 1)
  var st_keywords   = get(g:, 'tokyonight_italic_keywords', 1)
  var st_functions  = get(g:, 'tokyonight_italic_functions', 0)
  var st_variables  = get(g:, 'tokyonight_italic_variables', 0)
  var opt_sidebars  = get(g:, 'tokyonight_sidebars', 'dark')
  var opt_floats    = get(g:, 'tokyonight_floats', 'dark')

  # Build the resolved colour table -------------------------------------------
  var c = copy(palettes[style])
  bg_color = c.bg
  fg_color = c.fg

  c.none             = 'NONE'
  c.black            = Blend(c.bg, 0.8, '#000000')
  c.border           = c.black
  c.border_highlight = BlendBg(c.blue1, 0.8)
  c.bg_popup         = c.bg_dark
  c.bg_statusline    = c.bg_dark
  c.bg_visual        = BlendBg(c.blue0, 0.4)
  c.bg_search        = c.blue0
  c.fg_sidebar       = c.fg_dark
  c.fg_float         = c.fg
  c.diff_add         = BlendBg(c.green2, 0.25)
  c.diff_delete      = BlendBg(c.red1, 0.25)
  c.diff_change      = BlendBg(c.blue7, 0.15)
  c.diff_text        = c.blue7
  c.git_ignore       = c.dark3
  c.error            = c.red1
  c.todo             = c.blue
  c.warning          = c.yellow
  c.info             = c.blue2
  c.hint             = c.teal

  var SideBg = (style_opt: string): string =>
    style_opt == 'transparent' ? c.none : style_opt == 'dark' ? c.bg_dark : c.bg
  c.bg_sidebar = SideBg(opt_sidebars)
  c.bg_float   = SideBg(opt_floats)

  var norm_bg    = transparent ? c.none : c.bg
  var normnc_bg  = transparent ? c.none : dim_inactive ? c.bg_dark : c.bg
  var gutter_bg  = transparent ? c.none : c.bg
  var tabfill_bg = transparent ? c.none : c.black

  # rainbow (markdown headings, brackets, ...)
  var rainbow = [c.blue, c.yellow, c.green, c.teal, c.magenta, c.purple, c.orange, c.red]

  # Style helpers: start from a base spec and toggle italic per option.
  var SComment = (sp: dict<any>): dict<any> => st_comments  ? extend(sp, {italic: true}) : sp
  var SKeyword = (sp: dict<any>): dict<any> => st_keywords  ? extend(sp, {italic: true}) : sp
  var SFunc    = (sp: dict<any>): dict<any> => st_functions ? extend(sp, {italic: true}) : sp
  var SVar     = (sp: dict<any>): dict<any> => st_variables ? extend(sp, {italic: true}) : sp

  # ---------------------------------------------------------------------------
  # Editor UI
  # ---------------------------------------------------------------------------
  Hl('ColorColumn',  {bg: c.black})
  Hl('Conceal',      {fg: c.dark5})
  Hl('Cursor',       {fg: c.bg, bg: c.fg})
  Hl('lCursor',      {fg: c.bg, bg: c.fg})
  Hl('CursorIM',     {fg: c.bg, bg: c.fg})
  Hl('CursorColumn', {bg: c.bg_highlight})
  Hl('CursorLine',   {bg: c.bg_highlight})
  Hl('Directory',    {fg: c.blue})
  Hl('DiffAdd',      {bg: c.diff_add})
  Hl('DiffChange',   {bg: c.diff_change})
  Hl('DiffDelete',   {bg: c.diff_delete})
  Hl('DiffText',     {bg: c.diff_text})
  Hl('EndOfBuffer',  {fg: c.bg})
  Hl('ErrorMsg',     {fg: c.error})
  Hl('VertSplit',    {fg: c.border})
  Hl('WinSeparator', {fg: c.border, bold: true})
  Hl('Folded',       {fg: c.blue, bg: c.fg_gutter})
  Hl('FoldColumn',   {bg: gutter_bg, fg: c.comment})
  Hl('SignColumn',   {bg: gutter_bg, fg: c.fg_gutter})
  Hl('SignColumnSB', {bg: c.bg_sidebar, fg: c.fg_gutter})
  Hl('Substitute',   {bg: c.red, fg: c.black})
  Hl('LineNr',       {fg: c.fg_gutter})
  Hl('CursorLineNr', {fg: c.orange, bold: true})
  Hl('LineNrAbove',  {fg: c.fg_gutter})
  Hl('LineNrBelow',  {fg: c.fg_gutter})
  Hl('MatchParen',   {fg: c.cyan, bold: true})
  Hl('ModeMsg',      {fg: c.fg_dark, bold: true})
  Hl('MsgArea',      {fg: c.fg_dark})
  Hl('MoreMsg',      {fg: c.blue})
  Hl('NonText',      {fg: c.dark3})
  Hl('Normal',       {fg: c.fg, bg: norm_bg})
  Hl('NormalNC',     {fg: c.fg, bg: normnc_bg})
  Hl('NormalSB',     {fg: c.fg_sidebar, bg: c.bg_sidebar})
  Hl('NormalFloat',  {fg: c.fg_float, bg: c.bg_float})
  Hl('FloatBorder',  {fg: c.border_highlight, bg: c.bg_float})
  Hl('FloatTitle',   {fg: c.border_highlight, bg: c.bg_float})
  Hl('Pmenu',        {bg: c.bg_popup, fg: c.fg})
  Hl('PmenuMatch',   {bg: c.bg_popup, fg: c.blue1})
  Hl('PmenuSel',     {bg: BlendBg(c.fg_gutter, 0.8)})
  Hl('PmenuMatchSel', {bg: BlendBg(c.fg_gutter, 0.8), fg: c.blue1})
  Hl('PmenuSbar',    {bg: BlendFg(c.bg_popup, 0.95)})
  Hl('PmenuThumb',   {bg: c.fg_gutter})
  Hl('Question',     {fg: c.blue})
  Hl('QuickFixLine', {bg: c.bg_visual, bold: true})
  Hl('Search',       {bg: c.bg_search, fg: c.fg})
  Hl('IncSearch',    {bg: c.orange, fg: c.black})
  Hl('CurSearch',    'IncSearch')
  Hl('SpecialKey',   {fg: c.dark3})
  Hl('SpellBad',     {sp: c.error, undercurl: true})
  Hl('SpellCap',     {sp: c.warning, undercurl: true})
  Hl('SpellLocal',   {sp: c.info, undercurl: true})
  Hl('SpellRare',    {sp: c.hint, undercurl: true})
  Hl('StatusLine',   {fg: c.fg_sidebar, bg: c.bg_statusline})
  Hl('StatusLineNC', {fg: c.fg_gutter, bg: c.bg_statusline})
  Hl('TabLine',      {bg: c.bg_statusline, fg: c.fg_gutter})
  Hl('TabLineFill',  {bg: tabfill_bg})
  Hl('TabLineSel',   {fg: c.black, bg: c.blue})
  Hl('Title',        {fg: c.blue, bold: true})
  Hl('Visual',       {bg: BlendBg(c.blue0, 0.7)})
  Hl('VisualNOS',    {bg: BlendBg(c.blue0, 0.7)})
  Hl('WarningMsg',   {fg: c.warning})
  Hl('Whitespace',   {fg: c.fg_gutter})
  Hl('WildMenu',     {bg: c.bg_visual})
  Hl('WinBar',       'StatusLine')
  Hl('WinBarNC',     'StatusLineNC')

  # ---------------------------------------------------------------------------
  # Standard syntax groups
  # ---------------------------------------------------------------------------
  Hl('Bold',       {bold: true, fg: c.fg})
  Hl('Character',  {fg: c.green})
  Hl('Comment',    SComment({fg: c.comment}))
  Hl('Constant',   {fg: c.orange})
  Hl('Debug',      {fg: c.orange})
  Hl('Delimiter',  'Special')
  Hl('Error',      {fg: c.error})
  Hl('Function',   SFunc({fg: c.blue}))
  Hl('Identifier', SVar({fg: c.magenta}))
  Hl('Italic',     {italic: true, fg: c.fg})
  Hl('Keyword',    SKeyword({fg: c.cyan}))
  Hl('Operator',   {fg: c.blue5})
  Hl('PreProc',    {fg: c.cyan})
  Hl('Special',    {fg: c.blue1})
  Hl('Statement',  {fg: c.magenta})
  Hl('String',     {fg: c.green})
  Hl('Todo',       {bg: c.yellow, fg: c.bg})
  Hl('Type',       {fg: c.blue1})
  Hl('Underlined', {underline: true})

  # Common linked syntax groups (so plain Vim syntax files are fully coloured).
  Hl('Boolean',       'Constant')
  Hl('Number',        'Constant')
  Hl('Float',         'Constant')
  Hl('Conditional',   'Statement')
  Hl('Repeat',        'Statement')
  Hl('Label',         'Statement')
  Hl('Exception',     'Statement')
  Hl('Include',       'PreProc')
  Hl('Define',        'PreProc')
  Hl('Macro',         'PreProc')
  Hl('PreCondit',     'PreProc')
  Hl('StorageClass',  'Type')
  Hl('Structure',     'Type')
  Hl('Typedef',       'Type')
  Hl('Tag',           'Special')
  Hl('SpecialChar',   'Special')
  Hl('SpecialComment', 'Special')

  Hl('debugBreakpoint', {bg: BlendBg(c.info, 0.1), fg: c.info})
  Hl('debugPC',         {bg: c.bg_sidebar})
  Hl('dosIniLabel',     '@property')
  Hl('helpCommand',     {bg: c.terminal_black, fg: c.blue})
  Hl('helpExample',     {fg: c.comment})
  Hl('htmlH1',          {fg: c.magenta, bold: true})
  Hl('htmlH2',          {fg: c.blue, bold: true})
  Hl('qfFileName',      {fg: c.blue})
  Hl('qfLineNr',        {fg: c.dark5})

  # ---------------------------------------------------------------------------
  # LSP / diagnostics
  # ---------------------------------------------------------------------------
  Hl('LspReferenceText',             {bg: c.fg_gutter})
  Hl('LspReferenceRead',             {bg: c.fg_gutter})
  Hl('LspReferenceWrite',            {bg: c.fg_gutter})
  Hl('LspSignatureActiveParameter',  {bg: BlendBg(c.bg_visual, 0.4), bold: true})
  Hl('LspCodeLens',                  {fg: c.comment})
  Hl('LspInlayHint',                 {bg: BlendBg(c.blue7, 0.1), fg: c.dark3})
  Hl('LspInfoBorder',                {fg: c.border_highlight, bg: c.bg_float})
  Hl('ComplHint',                    {fg: c.terminal_black})

  Hl('DiagnosticError',            {fg: c.error})
  Hl('DiagnosticWarn',             {fg: c.warning})
  Hl('DiagnosticInfo',             {fg: c.info})
  Hl('DiagnosticHint',             {fg: c.hint})
  Hl('DiagnosticUnnecessary',      {fg: c.terminal_black})
  Hl('DiagnosticVirtualTextError', {bg: BlendBg(c.error, 0.1), fg: c.error})
  Hl('DiagnosticVirtualTextWarn',  {bg: BlendBg(c.warning, 0.1), fg: c.warning})
  Hl('DiagnosticVirtualTextInfo',  {bg: BlendBg(c.info, 0.1), fg: c.info})
  Hl('DiagnosticVirtualTextHint',  {bg: BlendBg(c.hint, 0.1), fg: c.hint})
  Hl('DiagnosticUnderlineError',   {undercurl: true, sp: c.error})
  Hl('DiagnosticUnderlineWarn',    {undercurl: true, sp: c.warning})
  Hl('DiagnosticUnderlineInfo',    {undercurl: true, sp: c.info})
  Hl('DiagnosticUnderlineHint',    {undercurl: true, sp: c.hint})

  Hl('healthError',   {fg: c.error})
  Hl('healthSuccess', {fg: c.green1})
  Hl('healthWarning', {fg: c.warning})

  # ---------------------------------------------------------------------------
  # diff / git
  # ---------------------------------------------------------------------------
  Hl('diffAdded',     {bg: c.diff_add, fg: c.git_add})
  Hl('diffRemoved',   {bg: c.diff_delete, fg: c.git_delete})
  Hl('diffChanged',   {bg: c.diff_change, fg: c.git_change})
  Hl('diffOldFile',   {fg: c.blue1, bg: c.diff_delete})
  Hl('diffNewFile',   {fg: c.blue1, bg: c.diff_add})
  Hl('diffFile',      {fg: c.blue})
  Hl('diffLine',      {fg: c.comment})
  Hl('diffIndexLine', {fg: c.magenta})

  # ---------------------------------------------------------------------------
  # Tree-sitter capture groups
  # ---------------------------------------------------------------------------
  Hl('@annotation',                 'PreProc')
  Hl('@attribute',                  'PreProc')
  Hl('@boolean',                    'Boolean')
  Hl('@character',                  'Character')
  Hl('@character.printf',           'SpecialChar')
  Hl('@character.special',          'SpecialChar')
  Hl('@comment',                    'Comment')
  Hl('@comment.error',             {fg: c.error})
  Hl('@comment.hint',              {fg: c.hint})
  Hl('@comment.info',              {fg: c.info})
  Hl('@comment.note',              {fg: c.hint})
  Hl('@comment.todo',              {fg: c.todo})
  Hl('@comment.warning',           {fg: c.warning})
  Hl('@constant',                   'Constant')
  Hl('@constant.builtin',           'Special')
  Hl('@constant.macro',             'Define')
  Hl('@constructor',               {fg: c.magenta})
  Hl('@constructor.tsx',           {fg: c.blue1})
  Hl('@diff.delta',                 'DiffChange')
  Hl('@diff.minus',                 'DiffDelete')
  Hl('@diff.plus',                  'DiffAdd')
  Hl('@function',                   'Function')
  Hl('@function.builtin',           'Special')
  Hl('@function.call',              '@function')
  Hl('@function.macro',             'Macro')
  Hl('@function.method',            'Function')
  Hl('@function.method.call',       '@function.method')
  Hl('@keyword',                   SKeyword({fg: c.purple}))
  Hl('@keyword.conditional',        'Conditional')
  Hl('@keyword.coroutine',          '@keyword')
  Hl('@keyword.debug',              'Debug')
  Hl('@keyword.directive',          'PreProc')
  Hl('@keyword.directive.define',   'Define')
  Hl('@keyword.exception',          'Exception')
  Hl('@keyword.function',          SFunc({fg: c.magenta}))
  Hl('@keyword.import',             'Include')
  Hl('@keyword.operator',           '@operator')
  Hl('@keyword.repeat',             'Repeat')
  Hl('@keyword.return',             '@keyword')
  Hl('@keyword.storage',            'StorageClass')
  Hl('@label',                     {fg: c.blue})
  Hl('@markup',                     '@none')
  Hl('@markup.emphasis',           {italic: true})
  Hl('@markup.environment',         'Macro')
  Hl('@markup.environment.name',    'Type')
  Hl('@markup.heading',             'Title')
  Hl('@markup.italic',             {italic: true})
  Hl('@markup.link',               {fg: c.teal})
  Hl('@markup.link.label',          'SpecialChar')
  Hl('@markup.link.label.symbol',   'Identifier')
  Hl('@markup.link.url',            'Underlined')
  Hl('@markup.list',               {fg: c.blue5})
  Hl('@markup.list.checked',       {fg: c.green1})
  Hl('@markup.list.markdown',      {fg: c.orange, bold: true})
  Hl('@markup.list.unchecked',     {fg: c.blue})
  Hl('@markup.math',                'Special')
  Hl('@markup.raw',                 'String')
  Hl('@markup.raw.markdown_inline', {bg: c.terminal_black, fg: c.blue})
  Hl('@markup.strikethrough',      {strikethrough: true})
  Hl('@markup.strong',             {bold: true})
  Hl('@markup.underline',          {underline: true})
  Hl('@module',                     'Include')
  Hl('@module.builtin',            {fg: c.red})
  Hl('@namespace.builtin',          '@variable.builtin')
  Hl('@none',                       {})
  Hl('@number',                     'Number')
  Hl('@number.float',               'Float')
  Hl('@operator',                  {fg: c.blue5})
  Hl('@property',                  {fg: c.green1})
  Hl('@punctuation.bracket',       {fg: c.fg_dark})
  Hl('@punctuation.delimiter',     {fg: c.blue5})
  Hl('@punctuation.special',       {fg: c.blue5})
  Hl('@punctuation.special.markdown', {fg: c.orange})
  Hl('@string',                     'String')
  Hl('@string.documentation',      {fg: c.yellow})
  Hl('@string.escape',             {fg: c.magenta})
  Hl('@string.regexp',             {fg: c.blue6})
  Hl('@tag',                        'Label')
  Hl('@tag.attribute',              '@property')
  Hl('@tag.delimiter',              'Delimiter')
  Hl('@tag.delimiter.tsx',         {fg: BlendBg(c.blue, 0.7)})
  Hl('@tag.tsx',                   {fg: c.red})
  Hl('@tag.javascript',            {fg: c.red})
  Hl('@type',                       'Type')
  Hl('@type.builtin',              {fg: BlendBg(c.blue1, 0.8)})
  Hl('@type.definition',            'Typedef')
  Hl('@type.qualifier',             '@keyword')
  Hl('@variable',                  SVar({fg: c.fg}))
  Hl('@variable.builtin',          {fg: c.red})
  Hl('@variable.member',           {fg: c.green1})
  Hl('@variable.parameter',        {fg: c.yellow})
  Hl('@variable.parameter.builtin', {fg: BlendFg(c.yellow, 0.8)})

  for i in range(len(rainbow))
    var col = rainbow[i]
    Hl(printf('@markup.heading.%d.markdown', i + 1), {fg: col, bold: true, bg: BlendBg(col, 0.1)})
  endfor

  # ---------------------------------------------------------------------------
  # LSP semantic tokens
  # ---------------------------------------------------------------------------
  Hl('@lsp.type.boolean',                      '@boolean')
  Hl('@lsp.type.builtinType',                  '@type.builtin')
  Hl('@lsp.type.comment',                      '@comment')
  Hl('@lsp.type.decorator',                    '@attribute')
  Hl('@lsp.type.deriveHelper',                 '@attribute')
  Hl('@lsp.type.enum',                         '@type')
  Hl('@lsp.type.enumMember',                   '@constant')
  Hl('@lsp.type.escapeSequence',               '@string.escape')
  Hl('@lsp.type.formatSpecifier',              '@markup.list')
  Hl('@lsp.type.generic',                      '@variable')
  Hl('@lsp.type.interface',                    {fg: BlendFg(c.blue1, 0.7)})
  Hl('@lsp.type.keyword',                      '@keyword')
  Hl('@lsp.type.lifetime',                     '@keyword.storage')
  Hl('@lsp.type.namespace',                    '@module')
  Hl('@lsp.type.namespace.python',             '@variable')
  Hl('@lsp.type.number',                       '@number')
  Hl('@lsp.type.operator',                     '@operator')
  Hl('@lsp.type.parameter',                    '@variable.parameter')
  Hl('@lsp.type.property',                     '@property')
  Hl('@lsp.type.selfKeyword',                  '@variable.builtin')
  Hl('@lsp.type.selfTypeKeyword',              '@variable.builtin')
  Hl('@lsp.type.string',                       '@string')
  Hl('@lsp.type.typeAlias',                    '@type.definition')
  Hl('@lsp.type.unresolvedReference',          {undercurl: true, sp: c.error})
  Hl('@lsp.type.variable',                     {})
  Hl('@lsp.typemod.class.defaultLibrary',      '@type.builtin')
  Hl('@lsp.typemod.enum.defaultLibrary',       '@type.builtin')
  Hl('@lsp.typemod.enumMember.defaultLibrary', '@constant.builtin')
  Hl('@lsp.typemod.function.defaultLibrary',   '@function.builtin')
  Hl('@lsp.typemod.keyword.async',             '@keyword.coroutine')
  Hl('@lsp.typemod.keyword.injected',          '@keyword')
  Hl('@lsp.typemod.macro.defaultLibrary',      '@function.builtin')
  Hl('@lsp.typemod.method.defaultLibrary',     '@function.builtin')
  Hl('@lsp.typemod.operator.injected',         '@operator')
  Hl('@lsp.typemod.string.injected',           '@string')
  Hl('@lsp.typemod.struct.defaultLibrary',     '@type.builtin')
  Hl('@lsp.typemod.type.defaultLibrary',       {fg: BlendBg(c.blue1, 0.8)})
  Hl('@lsp.typemod.typeAlias.defaultLibrary',  {fg: BlendBg(c.blue1, 0.8)})
  Hl('@lsp.typemod.variable.callable',         '@function')
  Hl('@lsp.typemod.variable.defaultLibrary',   '@variable.builtin')
  Hl('@lsp.typemod.variable.injected',         '@variable')
  Hl('@lsp.typemod.variable.static',           '@constant')

  # ---------------------------------------------------------------------------
  # LSP symbol-kind / completion-kind highlights
  # ---------------------------------------------------------------------------
  var kinds = {
    Array: '@punctuation.bracket', Boolean: '@boolean', Class: '@type',
    Color: 'Special', Constant: '@constant', Constructor: '@constructor',
    Enum: '@lsp.type.enum', EnumMember: '@lsp.type.enumMember', Event: 'Special',
    Field: '@variable.member', File: 'Normal', Folder: 'Directory',
    Function: '@function', Interface: '@lsp.type.interface', Key: '@variable.member',
    Keyword: '@lsp.type.keyword', Method: '@function.method', Module: '@module',
    Namespace: '@module', Null: '@constant.builtin', Number: '@number',
    Object: '@constant', Operator: '@operator', Package: '@module',
    Property: '@property', Reference: '@markup.link', Snippet: 'Conceal',
    String: '@string', Struct: '@lsp.type.struct', Unit: '@lsp.type.struct',
    Text: '@markup', TypeParameter: '@lsp.type.typeParameter', Variable: '@variable',
    Value: '@string',
  }
  for [kind, link] in items(kinds)
    Hl('LspKind' .. kind, link)
  endfor

  # Terminal colours ----------------------------------------------------------
  if term_colors
    Terminal(c, style)
  endif
enddef
