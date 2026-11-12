-- oil.nvim lets you edit your filesystem like a normal buffer
-- https://github.com/stevearc/oil.nvim

vim.pack.add {
  { src = 'https://github.com/stevearc/oil.nvim', version = 'v2.16.0' },
}

require('oil').setup {
  keymaps = {
    ['<C-s>'] = false,
  },
}

vim.keymap.set('n', '<leader>o', '<Cmd>Oil<CR>', { desc = 'Open oil (parent directory)', silent = true })
