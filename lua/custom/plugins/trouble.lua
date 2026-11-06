-- trouble.nvim: a live, toggleable diagnostics panel across all open buffers
-- https://github.com/folke/trouble.nvim
--
-- In the panel: j/k move (the main window previews each item), <CR> jump, o jump and close,
-- gb toggle "current buffer only", s cycle severity filter, zc/zo fold a file, ? for help.
-- Outside the panel it follows your cursor, highlighting the issue nearest to it.

vim.pack.add {
  -- main: v3.7.1 calls a treesitter internal removed in Neovim 0.12
  { src = 'https://github.com/folke/trouble.nvim', version = 'main' },
}

require('trouble').setup {
  focus = true, -- jump into the panel when opening it, like the file explorer
  follow = true, -- highlight the item at the cursor in the current buffer
  auto_refresh = true, -- update as diagnostics change while you edit
  modes = {
    diagnostics = {
      win = { position = 'bottom', size = 12 },
    },
  },
}

vim.keymap.set('n', '<leader>q', function() require('trouble').toggle 'diagnostics' end, { desc = 'Toggle diagnostics panel ([Q]uickfix)' })
