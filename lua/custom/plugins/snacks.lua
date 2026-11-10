-- [[ Snacks ]]
-- Only the snacks listed here are enabled; everything else stays off.
-- See `:help snacks-lazygit`, `:help snacks-dashboard` and `:help snacks-picker`.
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
  -- Only used for <leader><leader> for now; Telescope still handles everything else,
  -- including vim.ui.select (via telescope-ui-select).
  picker = { enabled = true, ui_select = false },
}

vim.keymap.set('n', '<leader>g', function() Snacks.lazygit() end, { desc = 'Lazy[G]it' })
-- Fuzzy file finder ranked by frecency: open buffers, recent files, then all files in the cwd.
vim.keymap.set('n', '<leader><leader>', function() Snacks.picker.smart() end, { desc = 'Search Files (recent first)' })

-- vim: ts=2 sts=2 sw=2 et
