-- [[ Snacks ]]
-- Only the lazygit snack is enabled; other snacks stay off unless listed here.
-- See `:help snacks-lazygit`.
vim.pack.add { 'https://github.com/folke/snacks.nvim' }
require('snacks').setup {
  lazygit = { enabled = true }, -- floating lazygit, themed to match the current colorscheme
}

vim.keymap.set('n', '<leader>g', function() Snacks.lazygit() end, { desc = 'Lazy[G]it' })

-- vim: ts=2 sts=2 sw=2 et
