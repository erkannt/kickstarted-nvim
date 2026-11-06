-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

-- Always (re)open rooted at the cwd, so a root set inside neo-tree is only temporary
vim.keymap.set('n', '<leader>e', function()
  require('neo-tree.command').execute { toggle = true, reveal = true, dir = vim.fn.getcwd() }
end, { desc = 'Toggle file [e]xplorer', silent = true })

require('neo-tree').setup {
  filesystem = {
    -- Setting the root (`.` / `<bs>`) only changes the view, not Neovim's cwd
    bind_to_cwd = false,
    -- Let oil.nvim handle opening directories (e.g. `nvim .`)
    hijack_netrw_behavior = 'disabled',
  },
}
