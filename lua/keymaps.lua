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
-- Toggle the diagnostics list (a location list, i.e. per-window quickfix list)
vim.keymap.set('n', '<leader>q', function()
  if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
    vim.cmd.lclose()
  else
    vim.diagnostic.setloclist()
  end
end, { desc = 'Toggle diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>td', function()
  local shown = vim.diagnostic.config().virtual_text ~= false
  if shown then
    vim.diagnostic.config { virtual_text = false }
  else
    vim.diagnostic.config { virtual_text = { source = 'if_many' } }
  end
  vim.notify('Diagnostic virtual text ' .. (shown and 'off' or 'on'))
end, { desc = '[R]oggle [D]iagnostic virtual text' })

-- CODE / COMMENTS
-- ----------------------------------------------------------
-- Remove Neovim's default `gr*` LSP keymaps (grn, gra, grr, ...) so `gr` alone is
-- free for "goto references" without a delay. LSP keymaps are set on LspAttach in
-- lua/kickstart/plugins/lspconfig.lua and lua/kickstart/plugins/telescope.lua.
for _, lhs in ipairs { 'grn', 'gra', 'grx', 'grr', 'gri', 'grt' } do
  pcall(vim.keymap.del, 'n', lhs)
end
pcall(vim.keymap.del, 'x', 'gra')

-- Toggle comments with <leader>cc instead of the default gc/gcc.
-- (The `gc` comment text object, e.g. `dgc`, is kept.)
pcall(vim.keymap.del, { 'n', 'x' }, 'gc')
pcall(vim.keymap.del, 'n', 'gcc')
vim.keymap.set('n', '<leader>cc', function() return require('vim._comment').operator() .. '_' end, { expr = true, desc = '[C]omment line' })
vim.keymap.set('x', '<leader>cc', function() return require('vim._comment').operator() end, { expr = true, desc = '[C]omment selection' })

-- TAB PAGES
-- ----------------------------------------------------------
-- Tab pages aren't used (buffers are managed via the buffer tree, <leader>bt), so disable the
-- built-in tab page keys. This also frees `gt` for "goto type definition" in LSP buffers.
for _, lhs in ipairs { 'gt', 'gT', 'g<Tab>', '<C-w>gt', '<C-w>gT', '<C-w>g<Tab>', '<C-w>T' } do
  vim.keymap.set('n', lhs, '<Nop>')
end
vim.keymap.set({ 'n', 'i' }, '<C-PageUp>', '<Nop>')
vim.keymap.set({ 'n', 'i' }, '<C-PageDown>', '<Nop>')

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

-- Cycle through buffers in most-recently-used order, like alt-tab: one <C-t> goes to the
-- previous buffer, pressing it again within a second keeps going further back (the order is
-- frozen while cycling). Replaces <C-t> tag-stack pop; use <C-o> to jump back instead.
do
  -- Exact recency (getbufinfo's `lastused` only has 1-second resolution)
  local tick, used = 0, {}
  vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('buffer-mru', { clear = true }),
    callback = function(ev)
      tick = tick + 1
      used[ev.buf] = tick
    end,
  })

  local cycle = { list = {}, index = 1, last = 0 }
  vim.keymap.set('n', '<C-t>', function()
    local now = vim.uv.now()
    if now - cycle.last > 1000 then
      local bufs = vim.tbl_filter(is_file_buf, vim.api.nvim_list_bufs())
      local current = vim.api.nvim_get_current_buf()
      -- current buffer first, then the rest by most recent use
      table.sort(bufs, function(a, b)
        if (a == current) ~= (b == current) then return a == current end
        return (used[a] or 0) > (used[b] or 0)
      end)
      cycle.list, cycle.index = bufs, 1
    end
    cycle.last = now
    -- advance to the next still-valid buffer in the frozen list
    for _ = 1, #cycle.list do
      cycle.index = cycle.index % #cycle.list + 1
      local buf = cycle.list[cycle.index]
      if vim.api.nvim_buf_is_valid(buf) and is_file_buf(buf) and buf ~= vim.api.nvim_get_current_buf() then
        return vim.api.nvim_set_current_buf(buf)
      end
    end
    vim.notify('No other buffer', vim.log.levels.INFO)
  end, { desc = 'Cycle buffers (most recent first)' })
end

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
