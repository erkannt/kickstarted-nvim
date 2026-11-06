-- flash.nvim lets you jump anywhere on screen with a few keystrokes
-- https://github.com/folke/flash.nvim

vim.pack.add {
  { src = 'https://github.com/folke/flash.nvim', version = 'v2.1.0' },
}

require('flash').setup {
  -- Leave the built-in f/F/t/T motions alone
  modes = { char = { enabled = false } },
}

-- `s` jumps to a label (`S` is used by mini.surround, see lua/kickstart/plugins/mini.lua)
vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = 'Flash' })
