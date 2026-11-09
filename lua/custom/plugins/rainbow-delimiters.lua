-- [[ Rainbow delimiters ]]
-- Colour matching brackets by nesting depth, using Tree-sitter (so brackets in strings and
-- comments are ignored). Works with defaults; see `:help rainbow-delimiters`.
--
-- Colours come from the colorscheme's `RainbowDelimiter{Red,Yellow,Blue,Orange,Green,Violet,Cyan}`
-- groups: tokyonight defines all seven, nordic is extended in `kickstart/plugins/colorscheme.lua`.
vim.pack.add { 'https://github.com/HiPhish/rainbow-delimiters.nvim' }

-- vim: ts=2 sts=2 sw=2 et
