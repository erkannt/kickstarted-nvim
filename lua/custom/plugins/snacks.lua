-- [[ Snacks ]]
-- Only the snacks listed here are enabled; everything else stays off.
-- See `:help snacks-lazygit` and `:help snacks-dashboard`.
vim.pack.add { 'https://github.com/folke/snacks.nvim' }

local logo = require 'custom.rknt_logo'
logo.set_highlights()
-- Logo colours derive from the theme, so recompute them whenever it changes.
vim.api.nvim_create_autocmd('ColorScheme', { callback = logo.set_highlights })

require('snacks').setup {
  lazygit = { enabled = true }, -- floating lazygit, themed to match the current colorscheme
  dashboard = {
    enabled = true,
    width = logo.width, -- the pane must be as wide as the logo to centre it
    sections = { { text = logo.text, align = 'center' } },
  },
}

vim.keymap.set('n', '<leader>g', function() Snacks.lazygit() end, { desc = 'Lazy[G]it' })

-- vim: ts=2 sts=2 sw=2 et
