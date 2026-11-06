local function gh(repo) return 'https://github.com/' .. repo end

-- [[ mini.nvim ]]
--  A collection of various small independent plugins/modules
vim.pack.add { gh 'nvim-mini/mini.nvim' }

-- If a nerd font is available, load the icons module for pretty icons in various plugins.
if vim.g.have_nerd_font then
  require('mini.icons').setup()
  -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
  MiniIcons.mock_nvim_web_devicons()
end

-- Better Around/Inside textobjects
--
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yiNq - [Y]ank [I]nside [N]ext [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
require('mini.ai').setup {
  -- NOTE: Leave the built-in incremental selection mappings `an`/`in` alone (see
  -- `:help treesitter-incremental-selection`) by parking mini.ai's "next" variants on `aN`/`iN`.
  -- Use '' instead if you would rather drop them entirely.
  mappings = {
    around_next = 'aN',
    inside_next = 'iN',
  },
  n_lines = 500,
}

-- Incremental treesitter selection on `aa`/`ii`, as aliases for the built-in `an`/`in`.
--  - aa - grow the selection to the parent node
--  - ii - shrink the selection to the child node
-- NOTE: `aa` shadows mini.ai's [a]rgument textobject; `ia`/`aN`/`iN` are unaffected.
vim.keymap.set({ 'x', 'o' }, 'aa', 'an', { remap = true, desc = 'Select parent (outer) node' })
vim.keymap.set({ 'x', 'o' }, 'ii', 'in', { remap = true, desc = 'Select child (inner) node' })

-- Add/delete/replace surroundings (brackets, quotes, etc.)
--
-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - sd'   - [S]urround [D]elete [']quotes
-- - sr)'  - [S]urround [R]eplace [)] [']
require('mini.surround').setup()

-- Simple and easy statusline.
--  You could remove this setup call if you don't like it,
--  and try some other statusline plugin
local statusline = require 'mini.statusline'
-- Set `use_icons` to true if you have a Nerd Font
statusline.setup { use_icons = vim.g.have_nerd_font }

-- You can configure sections in the statusline by overriding their
-- default behavior. For example, here we set the section for
-- cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- Show listed buffers as tabs along the top
require('mini.tabline').setup { show_icons = vim.g.have_nerd_font }

-- vim: ts=2 sts=2 sw=2 et
