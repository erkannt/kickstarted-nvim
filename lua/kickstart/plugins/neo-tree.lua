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

-- Buffer jumper: open buffers as a tree in the sidebar, with flash labels on each file.
--   <leader>bj, then a label  -> open that buffer (and close the sidebar)
--   <leader>bj, then <Esc>    -> stay in the tree: j/k + <CR>/l to open, d to close a buffer
--   <leader>bj while it's open -> close it
local function buffers_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.b[vim.api.nvim_win_get_buf(win)].neo_tree_source == 'buffers' then return win end
  end
end

local function buffer_jump()
  local command = require 'neo-tree.command'
  if buffers_win() then return command.execute { source = 'buffers', action = 'close' } end

  command.execute { source = 'buffers', action = 'focus', reveal = true }
  vim.schedule(function()
    local win = buffers_win()
    if not win or win ~= vim.api.nvim_get_current_win() then return end
    local state = require('neo-tree.sources.manager').get_state 'buffers'

    require('flash').jump {
      search = { mode = 'search', max_length = 0, multi_window = false },
      label = { after = { 0, 0 }, uppercase = false },
      highlight = { backdrop = false },
      -- One label per file node (skip directories)
      matcher = function(w)
        if w ~= win or not state.tree then return {} end
        local matches = {}
        for lnum = 1, vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(w)) do
          local ok, node = pcall(state.tree.get_node, state.tree, lnum)
          if ok and node and node.type == 'file' then table.insert(matches, { pos = { lnum, 0 }, end_pos = { lnum, 0 } }) end
        end
        return matches
      end,
      action = function(match)
        vim.api.nvim_win_set_cursor(win, match.pos)
        require('neo-tree.sources.buffers.commands').open(state)
        command.execute { source = 'buffers', action = 'close' }
      end,
    }
  end)
end

vim.keymap.set('n', '<leader>bj', buffer_jump, { desc = '[B]uffer [J]ump (tree of open buffers)', silent = true })

require('neo-tree').setup {
  window = {
    mappings = {
      -- Navigate the tree like snacks explorer
      ['h'] = 'close_node', -- collapse dir, or jump to and collapse the parent
      ['l'] = 'open', -- expand/collapse dir, or open file
    },
  },
  filesystem = {
    -- Setting the root (`.` / `<bs>`) only changes the view, not Neovim's cwd
    bind_to_cwd = false,
    -- Let oil.nvim handle opening directories (e.g. `nvim .`)
    hijack_netrw_behavior = 'disabled',
  },
}
