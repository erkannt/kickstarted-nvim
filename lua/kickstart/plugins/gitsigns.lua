local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
local gitsigns = require 'gitsigns'

-- [[ Live hunk quickfix list ]]
-- gitsigns.setqflist() is a one-off snapshot. Remember which list we made, and rebuild it
-- whenever gitsigns recomputes hunks (as you edit / on save) while that list is still the
-- current quickfix list and its window is open. The selected entry is kept where possible.
local hunk_qf ---@type { target: integer|'all', id: integer }?

---@param target integer|'all' buffer number, or 'all' files in the repo
local function hunk_qflist(target)
  gitsigns.setqflist(target, nil, function(err)
    if err then return end
    vim.schedule(function() hunk_qf = { target = target, id = vim.fn.getqflist({ id = 0 }).id } end)
  end)
end

local function refresh_hunk_qflist()
  if not hunk_qf or vim.fn.getqflist({ id = 0 }).id ~= hunk_qf.id then return end -- another list took over
  local qf_win = vim.fn.getqflist({ winid = 0 }).winid
  if qf_win == 0 then return end -- window closed: stop updating until it's reopened
  local target = hunk_qf.target
  if type(target) == 'number' and not vim.api.nvim_buf_is_valid(target) then return end

  -- remember the selected entry, to re-select the same hunk in the new list
  local idx = vim.fn.getqflist({ idx = 0 }).idx
  local selected = vim.fn.getqflist({ idx = idx, items = 0 }).items[1]
  -- Step back one list first, so the new list replaces the old one instead of piling up in the
  -- quickfix history (`:colder`/`:cnewer`); creating a list frees all lists after the current one.
  if vim.fn.getqflist({ nr = 0 }).nr > 1 then vim.cmd 'silent colder' end
  gitsigns.setqflist(target, { open = false }, function(err)
    if err then return end
    vim.schedule(function()
      local list = vim.fn.getqflist { id = 0, size = 0 }
      hunk_qf = { target = target, id = list.id }
      if list.size == 0 then return end
      idx = math.min(idx, list.size)
      if selected then
        -- same file, nearest line (hunks above it may have grown or shrunk)
        local best
        for i, item in ipairs(vim.fn.getqflist()) do
          if item.bufnr == selected.bufnr then
            local dist = math.abs(item.lnum - selected.lnum)
            if not best or dist < best then
              best, idx = dist, i
            end
          end
        end
      end
      vim.fn.setqflist({}, 'a', { id = list.id, idx = idx })
      if vim.api.nvim_win_is_valid(qf_win) then vim.api.nvim_win_set_cursor(qf_win, { idx, 0 }) end
    end)
  end)
end

local refresh_timer = assert(vim.uv.new_timer())
vim.api.nvim_create_autocmd('User', {
  pattern = 'GitSignsUpdate',
  group = vim.api.nvim_create_augroup('gitsigns-live-qflist', { clear = true }),
  callback = function()
    if not hunk_qf then return end
    refresh_timer:stop()
    refresh_timer:start(300, 0, vim.schedule_wrap(refresh_hunk_qflist))
  end,
})

gitsigns.setup {
  -- Use the native quickfix window for hunk lists (the live refresh above targets it);
  -- otherwise gitsigns opens them in trouble.nvim when that is installed.
  trouble = false,
  -- Also attach to files git doesn't track yet, so the hunk keymaps exist there too
  -- (the whole file shows as one added hunk until it's `git add`ed).
  attach_to_untracked = true,
  signs = {
    add = { text = '+' }, ---@diagnostic disable-line: missing-fields
    change = { text = '~' }, ---@diagnostic disable-line: missing-fields
    delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
    topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
    changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
  },
  -- gitsigns.nvim's recommended keymaps:
  on_attach = function(bufnr)
    -- Navigation
    vim.keymap.set('n', ']h', function()
      if vim.wo.diff then
        vim.cmd.normal { ']h', bang = true }
      else
        gitsigns.nav_hunk 'next'
      end
    end, { desc = 'Jump to next git [c]hange', buf = bufnr })

    vim.keymap.set('n', '[h', function()
      if vim.wo.diff then
        vim.cmd.normal { '[h', bang = true }
      else
        gitsigns.nav_hunk 'prev'
      end
    end, { desc = 'Jump to previous git [c]hange', buf = bufnr })

    -- Visual mode actions
    vim.keymap.set('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk', buf = bufnr })
    vim.keymap.set('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk', buf = bufnr })
    -- Normal mode actions
    vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk', buf = bufnr })
    vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk', buf = bufnr })
    vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer', buf = bufnr })
    vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer', buf = bufnr })
    vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk', buf = bufnr })
    vim.keymap.set('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline', buf = bufnr })
    vim.keymap.set('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, { desc = 'git [b]lame line', buf = bufnr })
    vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index', buf = bufnr })
    vim.keymap.set('n', '<leader>hD', function() gitsigns.diffthis '~' end, { desc = 'git [D]iff against last commit', buf = bufnr })
    vim.keymap.set('n', '<leader>hQ', function() hunk_qflist 'all' end, { desc = 'git hunk [Q]uickfix list (all files in repo)', buf = bufnr })
    vim.keymap.set('n', '<leader>hq', function() hunk_qflist(bufnr) end, { desc = 'git hunk [q]uickfix list (all changes in this file)', buf = bufnr })
    -- Toggles
    vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line', buf = bufnr })
    vim.keymap.set('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = '[T]oggle git intra-line [w]ord diff', buf = bufnr })
    -- Text object
    vim.keymap.set({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = 'text object [i]nside [h]unk', buf = bufnr })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
