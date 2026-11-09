local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Colorscheme ]]
-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
vim.pack.add { gh 'AlexvZyl/nordic.nvim' }
---@diagnostic disable-next-line: missing-fields
require('nordic').setup {
  after_palette = function(palette)
    local U = require 'nordic.utils'
    -- Higher contrast for visual selection
    palette.bg_visual = U.blend(palette.orange.base, palette.bg, 0.15)
  end,
  on_highlight = function(highlights, palette)
    local U = require 'nordic.utils'
    -- Higher contrast for current line number
    highlights.CursorLineNr = { fg = palette.magenta.base, bold = true }
    -- Visible LSP reference highlights (CursorHold)
    highlights.LspReferenceText = { bg = U.blend(palette.cyan.base, palette.bg, 0.10) }
    highlights.LspReferenceRead = { bg = U.blend(palette.cyan.base, palette.bg, 0.10) }
    highlights.LspReferenceWrite = { bg = U.blend(palette.yellow.base, palette.bg, 0.1) }
    -- rainbow-delimiters: nordic only defines 5 of the 7 levels. Cyan uses blue1 because
    -- nordic's cyan is nearly identical to the blue2 it uses for RainbowDelimiterBlue.
    highlights.RainbowDelimiterViolet = { fg = palette.magenta.bright }
    highlights.RainbowDelimiterCyan = { fg = palette.blue1 }
  end,
}

vim.pack.add { gh 'folke/tokyonight.nvim' }
---@diagnostic disable-next-line: missing-fields
require('tokyonight').setup {}

-- Themery needs every colorscheme plugin added above (via vim.pack.add) so
-- they're on the runtimepath before we scan for available colorschemes.
vim.pack.add { gh 'zaldih/themery.nvim' }
require('themery').setup {
  --themes = vim.fn.getcompletion('', 'color'),
  themes = { 'nordic', 'tokyonight-night', 'tokyonight-day' },
  livePreview = true,
}

vim.cmd.colorscheme 'nordic'

-- vim: ts=2 sts=2 sw=2 et
