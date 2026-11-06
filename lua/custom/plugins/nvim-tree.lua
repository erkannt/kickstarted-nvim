-- nvim-tree is a file explorer tree for Neovim
-- https://github.com/nvim-tree/nvim-tree.lua

-- Disable netrw, as recommended by nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.pack.add {
  { src = 'https://github.com/nvim-tree/nvim-tree.lua', version = 'v1.19.0' },
}

require('nvim-tree').setup {
  -- Let oil.nvim handle opening directories (e.g. `nvim .`)
  hijack_directories = { enable = false },
}

vim.keymap.set('n', '<leader>e', '<Cmd>NvimTreeToggle<CR>', { desc = 'Toggle nvim-tree', silent = true })
