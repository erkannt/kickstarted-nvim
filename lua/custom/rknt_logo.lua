-- Dashboard logo: 'rknt' in a stencilled ANSI style. The top of each letter is in
-- the theme's foreground tones and the bottom drips into its error/red accent.
-- Colours come from the active colorscheme, so call `set_highlights` on ColorScheme.
local M = {}

M.width = 35

local function hl_fg(name, fallback)
  local fg = vim.api.nvim_get_hl(0, { name = name, link = false }).fg
  return fg or fallback
end

-- Mix colour `a` into `b` by `t` (1 = all `a`); both are 24-bit integers.
local function blend(a, b, t)
  local function ch(c, s) return math.floor(c / 2 ^ s) % 256 end
  local out = 0
  for _, s in ipairs { 16, 8, 0 } do
    out = out + math.floor(ch(a, s) * t + ch(b, s) * (1 - t) + 0.5) * 2 ^ s
  end
  return out
end

function M.set_highlights()
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  local fg = normal.fg or 0xc0c0c0
  local bg = normal.bg or 0x000000
  local accent = hl_fg('Function', 0xe06c75)
  local set = vim.api.nvim_set_hl
  set(0, 'RkntLogoBright', { fg = fg, bold = true })
  set(0, 'RkntLogoMid', { fg = blend(fg, bg, 0.7) })
  set(0, 'RkntLogoDim', { fg = hl_fg('Comment', blend(fg, bg, 0.4)) })
  set(0, 'RkntLogoAccent', { fg = accent, bold = true })
  set(0, 'RkntLogoAccentDim', { fg = blend(accent, bg, 0.6) })
end

-- snacks.dashboard text list; `\n` at the start of a chunk begins a new line.
M.text = {
  { '         ' },
  { '@@@', hl = 'RkntLogoBright' },
  { '               ' },
  { '@@@', hl = 'RkntLogoBright' },
  { '     ' },
  { '\n         ' },
  { '@@', hl = 'RkntLogoBright' },
  { '@  ', hl = 'RkntLogoMid' },
  { '@!', hl = 'RkntLogoBright' },
  { ':', hl = 'RkntLogoDim' },
  { '          ' },
  { '@@', hl = 'RkntLogoBright' },
  { '@     ', hl = 'RkntLogoMid' },
  { '\n         ' },
  { '@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { '           ' },
  { '@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { '     ' },
  { '\n@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { '  ' },
  { '@', hl = 'RkntLogoBright' },
  { '@@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { '@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { '   ' },
  { '@@@@', hl = 'RkntLogoBright' },
  { '@@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { '  ' },
  { '@', hl = 'RkntLogoBright' },
  { '@@@@@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '\n@@@', hl = 'RkntLogoBright' },
  { '@@@@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '@@@@', hl = 'RkntLogoAccent' },
  { '@', hl = 'RkntLogoAccentDim' },
  { '@', hl = 'RkntLogoAccent' },
  { '@:', hl = 'RkntLogoDim' },
  { ' ' },
  { '@@@', hl = 'RkntLogoBright' },
  { '@@@@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '@', hl = 'RkntLogoBright' },
  { '@@', hl = 'RkntLogoMid' },
  { '@@@', hl = 'RkntLogoAccent' },
  { '@@', hl = 'RkntLogoDim' },
  { '\n@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '!', hl = 'RkntLogoAccent' },
  { '  ' },
  { '@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '@@@', hl = 'RkntLogoAccent' },
  { ' ' },
  { '!', hl = 'RkntLogoAccentDim' },
  { '@@', hl = 'RkntLogoAccent' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '!', hl = 'RkntLogoAccent' },
  { '  ' },
  { '@', hl = 'RkntLogoBright' },
  { '@', hl = 'RkntLogoMid' },
  { '@', hl = 'RkntLogoDim' },
  { ' @', hl = 'RkntLogoMid' },
  { '@@', hl = 'RkntLogoAccent' },
  { '     ' },
  { '\n!@!', hl = 'RkntLogoAccent' },
  { '  ' },
  { '@!', hl = 'RkntLogoAccent' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '@!@', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { '!@!', hl = 'RkntLogoAccent' },
  { ' ' },
  { '!@!', hl = 'RkntLogoAccent' },
  { '  ' },
  { '@!', hl = 'RkntLogoAccent' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '@!@', hl = 'RkntLogoAccent' },
  { '  ' },
  { '!@!', hl = 'RkntLogoAccent' },
  { '\n!!', hl = 'RkntLogoAccent' },
  { '@', hl = 'RkntLogoAccentDim' },
  { '   ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { '@@!', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { '@!', hl = 'RkntLogoAccentDim' },
  { '@', hl = 'RkntLogoDim' },
  { ' ' },
  { '!!', hl = 'RkntLogoAccent' },
  { '@', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { '!', hl = 'RkntLogoAccent' },
  { '@!', hl = 'RkntLogoAccentDim' },
  { ' ' },
  { '!@', hl = 'RkntLogoAccent' },
  { '!@!@!', hl = 'RkntLogoAccentDim' },
  { '@', hl = 'RkntLogoDim' },
  { '\n!', hl = 'RkntLogoAccentDim' },
  { ':', hl = 'RkntLogoAccent' },
  { '!', hl = 'RkntLogoAccentDim' },
  { '      ' },
  { '!@!', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { '@!:', hl = 'RkntLogoAccentDim' },
  { ' ' },
  { '!', hl = 'RkntLogoAccentDim' },
  { ':', hl = 'RkntLogoAccent' },
  { '!', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { '@:!', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { '!', hl = 'RkntLogoDim' },
  { '@!', hl = 'RkntLogoAccentDim' },
  { '@', hl = 'RkntLogoDim' },
  { '!!:', hl = 'RkntLogoAccentDim' },
  { '\n ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { '       ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { ' ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { '    ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { '   ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { ' ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { '   ' },
  { '!:', hl = 'RkntLogoAccentDim' },
  { '  ' },
  { ':', hl = 'RkntLogoAccentDim' },
  { ' ' },
}

return M
