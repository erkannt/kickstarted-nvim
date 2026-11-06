local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Fuzzy Finder (files, lsp, etc) ]]
--
-- Two important keymaps to use while in Telescope are:
--  - Insert mode: <c-/>
--  - Normal mode: ?

---@type (string | vim.pack.Spec)[]
local telescope_plugins = {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
  { src = gh 'nvim-telescope/telescope-frecency.nvim', version = '1.2.2' },
}
if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

-- NOTE: You can install multiple plugins at once
vim.pack.add(telescope_plugins)

-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  -- You can put your default mappings / updates / etc. in here
  --  All the info you're looking for is in `:help telescope.setup()`
  --
  -- defaults = {
  --   mappings = {
  --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
  --   },
  -- },
  -- pickers = {}
  defaults = {
    -- Prompt at the top, best match directly below it
    sorting_strategy = 'ascending',
    layout_config = { prompt_position = 'top' },
  },
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
    frecency = {
      default_workspace = 'CWD', -- only this project's files, plus all its other files below the history
      -- Substring matching: space-separated pieces of the path (e.g. `kick tele`). The
      -- 'fuzzy' matcher scores in pure Lua and was too slow on large repos.
      matcher = 'default',
      show_scores = false,
      -- Silently drop history entries for deleted files (checked once per session)
      db_safe_mode = false,
    },
  },
}

-- Enable Telescope extensions if they are installed
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')
pcall(require('telescope').load_extension, 'frecency')

-- See `:help telescope.builtin`
local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set(
  'n',
  '<leader><leader>',
  function() require('telescope').extensions.frecency.frecency { workspace = 'CWD' } end,
  { desc = 'Search Files (recent first)' }
)
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })

-- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
-- If you later switch picker plugins, this is where to update these mappings.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    -- These jump straight to the target when there is a single result,
    -- and open a Telescope picker when there are several.

    -- Find references for the word under your cursor.
    vim.keymap.set('n', 'gr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

    -- Jump to the implementation of the word under your cursor.
    -- Useful when your language has ways of declaring types without an actual implementation.
    vim.keymap.set('n', 'gI', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

    -- Jump to the definition of the word under your cursor.
    -- This is where a variable was first declared, or where a function is defined, etc.
    -- To jump back, press <C-o> (<C-t> cycles buffers, see lua/keymaps.lua).
    vim.keymap.set('n', 'gd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

    -- Fuzzy find all the symbols in your current document.
    -- Symbols are things like variables, functions, types, etc.
    vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

    -- Fuzzy find all the symbols in your current workspace.
    -- Similar to document symbols, except searches over your entire project.
    vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

    -- Jump to the type of the word under your cursor.
    -- Useful when you're not sure what type a variable is and you want to see
    -- the definition of its *type*, not where it was *defined*.
    vim.keymap.set('n', 'gt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
  end,
})

-- Override default behavior and theme when searching
-- Live grep across the project, optionally limited to a path.
-- Type `<text>  <path>` (two spaces) to only search files whose path contains <path>,
-- e.g. `canuse  src` or `setup  plugins/tele`. Without two spaces, the whole prompt is
-- the search text.
local function path_grep()
  local conf = require('telescope.config').values
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local opts = { cwd = vim.uv.cwd() }

  require('telescope.pickers')
    .new(opts, {
      prompt_title = 'Grep (text  path)',
      debounce = 100,
      finder = finders.new_async_job {
        command_generator = function(prompt)
          if not prompt or prompt == '' then return nil end
          local text, path = prompt:match '^(.-)  (.*)$'
          if not text then text = prompt end
          if text == '' then return nil end

          local args = vim.deepcopy(conf.vimgrep_arguments)
          if path and path ~= '' then
            -- Match files whose path contains <path>, whether it ends in a file or a directory name
            vim.list_extend(args, { '--iglob', '**/*' .. path .. '*', '--iglob', '**/*' .. path .. '*/**' })
          end
          return vim.list_extend(args, { '-e', text })
        end,
        entry_maker = make_entry.gen_from_vimgrep(opts),
        cwd = opts.cwd,
      },
      previewer = conf.grep_previewer(opts),
      sorter = require('telescope.sorters').empty(),
    })
    :find()
end
vim.keymap.set('n', '<leader>/', path_grep, { desc = '[/] Grep project (`text  path` to limit path)' })

-- It's also possible to pass additional configuration options.
--  See `:help telescope.builtin.live_grep()` for information about particular keys
vim.keymap.set(
  'n',
  '<leader>s/',
  function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end,
  { desc = '[S]earch [/] in Open Files' }
)

-- Shortcut for searching your Neovim configuration files
vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim files' })

-- vim: ts=2 sts=2 sw=2 et
