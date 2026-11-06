-- BASIC KEYMAPS
-- ----------------------------------------------------------
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- DIAGNOSTIC CONFIG & KEYMAPS
-- ----------------------------------------------------------
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = false, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float {
        bufnr = bufnr,
        scope = 'cursor',
        focus = false,
      }
    end,
  },
}

-- keybindings
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<Esc><cmd>write<CR>', { desc = '[S]ave current file' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>td', function()
  local shown = vim.diagnostic.config().virtual_text ~= false
  if shown then
    vim.diagnostic.config { virtual_text = false }
  else
    vim.diagnostic.config { virtual_text = { source = 'if_many' } }
  end
  vim.notify('Diagnostic virtual text ' .. (shown and 'off' or 'on'))
end, { desc = '[R]oggle [D]iagnostic virtual text' })

-- WINDOW NAV
-- ----------------------------------------------------------

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>wo', '<Cmd>only<CR>', { desc = 'Close [O]ther windows' })

-- BUFFERS
-- ----------------------------------------------------------
local function is_file_buf(buf) return vim.bo[buf].buflisted and vim.bo[buf].buftype == '' end

-- Keep only the most recent file buffer, in a single window. Works from
-- non-file windows too (e.g. neo-tree): they get closed along with the rest.
vim.keymap.set('n', '<leader>bo', function()
  local current = vim.api.nvim_get_current_buf()
  if not is_file_buf(current) then
    local recent
    for _, info in ipairs(vim.fn.getbufinfo { buflisted = 1 }) do
      if is_file_buf(info.bufnr) and (not recent or info.lastused > recent.lastused) then recent = info end
    end
    if not recent then
      vim.notify('No file buffer to keep', vim.log.levels.INFO)
      return
    end
    current = recent.bufnr
    local win = vim.fn.bufwinid(current)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
    else
      vim.cmd.sbuffer(current)
    end
  end
  vim.cmd.only()

  local skipped = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted then
      -- Keep buffers with unsaved changes rather than losing them
      if vim.bo[buf].modified then
        skipped = skipped + 1
      else
        vim.api.nvim_buf_delete(buf, {})
      end
    end
  end
  if skipped > 0 then vim.notify(('Kept %d modified buffer(s)'):format(skipped), vim.log.levels.WARN) end
end, { desc = 'Close [O]ther buffers' })

-- Cycle through buffers (the tabs in the tabline). Replaces the H/L screen-top/bottom motions.
vim.keymap.set('n', '<S-h>', '<Cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<S-l>', '<Cmd>bnext<CR>', { desc = 'Next buffer' })

-- Same as <C-^>: jump to the alternate buffer; pressing again jumps back
vim.keymap.set('n', '<leader>bb', function()
  local alt = vim.fn.bufnr '#'
  if alt == -1 or not vim.api.nvim_buf_is_valid(alt) or not vim.bo[alt].buflisted then
    vim.notify('No previous buffer', vim.log.levels.INFO)
    return
  end
  vim.api.nvim_set_current_buf(alt)
end, { desc = 'Switch to previous [B]uffer' })

-- YANK HIGHLIGHT
-- ----------------------------------------------------------
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- vim: ts=2 sts=2 sw=2 et
