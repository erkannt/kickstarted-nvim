local function gh(repo) return 'https://github.com/' .. repo end

-- [[ LSP Configuration ]]

-- Useful status updates for LSP.
vim.pack.add { gh 'j-hui/fidget.nvim' }
require('fidget').setup {}

-- [[ Progress for slow requests ]]
-- tsc and oxlint only report $/progress while loading a project; re-checking after an edit,
-- finding references etc. happen silently inside a normal request. Show those in fidget when
-- they take longer than `delay` ms (fast ones never appear, so nothing flickers).
do
  local delay = 300
  local watched_clients = { tsc = true, oxlint = true }
  -- Requests worth showing; background ones (semantic tokens, inlay hints, completion, ...) are skipped
  local labels = {
    ['textDocument/diagnostic'] = 'Checking',
    ['textDocument/definition'] = 'Finding definition',
    ['textDocument/typeDefinition'] = 'Finding type definition',
    ['textDocument/implementation'] = 'Finding implementations',
    ['textDocument/references'] = 'Finding references',
    ['textDocument/rename'] = 'Renaming',
    ['textDocument/prepareRename'] = 'Preparing rename',
    ['textDocument/codeAction'] = 'Loading code actions',
    ['textDocument/hover'] = 'Loading hover',
    ['textDocument/documentSymbol'] = 'Loading symbols',
    ['workspace/symbol'] = 'Searching symbols',
    ['workspace/executeCommand'] = 'Running command',
  }

  local pending = {} ---@type table<string, { timer: uv.uv_timer_t, handle?: ProgressHandle }>

  vim.api.nvim_create_autocmd('LspRequest', {
    group = vim.api.nvim_create_augroup('lsp-slow-request-progress', { clear = true }),
    callback = function(ev)
      local request = ev.data.request
      local label = labels[request.method]
      if not label then return end
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or not watched_clients[client.name] then return end

      local key = ev.data.client_id .. ':' .. ev.data.request_id
      if request.type == 'pending' then
        if pending[key] then return end
        local entry = { timer = assert(vim.uv.new_timer()) }
        pending[key] = entry
        local bufnr = request.bufnr
        entry.timer:start(
          delay,
          0,
          vim.schedule_wrap(function()
            if pending[key] ~= entry then return end
            local name = bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t') or nil
            entry.handle = require('fidget.progress').handle.create {
              title = label,
              message = name,
              lsp_client = { name = client.name },
            }
          end)
        )
      else -- 'complete' or 'cancel'
        local entry = pending[key]
        if not entry then return end
        pending[key] = nil
        entry.timer:stop()
        entry.timer:close()
        if entry.handle then
          if request.type == 'cancel' then
            entry.handle:cancel()
          else
            entry.handle:finish()
          end
        end
      end
    end,
  })
end

-- [[ Fix all + format ]]
-- <leader>cf runs the source actions below (for servers attached to the current buffer), in order,
-- waiting for each to be applied, then formats every open file buffer with conform.
local fix_all_steps = {
  { 'oxlint', 'source.fixAll.oxc' },
  { 'tsc', 'source.fixAll' },
  { 'tsc', 'source.removeUnusedImports' },
}
local fix_all_clients = {} ---@type table<string, true>
for _, step in ipairs(fix_all_steps) do
  fix_all_clients[step[1]] = true
end

local function format_all_buffers()
  local conform = require 'conform'
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == '' and vim.bo[buf].modifiable then
      conform.format { bufnr = buf, async = true }
    end
  end
end

--- Request the `kind` source action from `client` for the whole buffer, apply it, then call `done`.
---@param client vim.lsp.Client
---@param bufnr integer
---@param kind string
---@param done fun()
local function run_source_action(client, bufnr, kind, done)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.range = { start = { line = 0, character = 0 }, ['end'] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 } }
  params.context = { only = { kind }, diagnostics = {} }

  local function apply(action)
    if type(action.command) == 'string' then -- a bare Command rather than a CodeAction
      return client:exec_cmd(action --[[@as lsp.Command]], { bufnr = bufnr }, vim.schedule_wrap(done))
    end
    if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding) end
    if action.command then return client:exec_cmd(action.command, { bufnr = bufnr }, vim.schedule_wrap(done)) end
    done()
  end

  client:request('textDocument/codeAction', params, function(err, actions)
    if err then vim.notify(('%s %s failed: %s'):format(client.name, kind, err.message), vim.log.levels.ERROR) end
    local action = actions and actions[1]
    if not action then return done() end
    if action.edit or action.command or not client:supports_method 'codeAction/resolve' then return apply(action) end
    client:request('codeAction/resolve', action, function(_, resolved) apply(resolved or action) end, bufnr)
  end, bufnr)
end

---@param bufnr integer
local function fix_all_and_format(bufnr)
  local steps = {}
  for _, step in ipairs(fix_all_steps) do
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = step[1] })[1]
    if client then table.insert(steps, { client, step[2] }) end
  end
  local function next_step(i)
    local step = steps[i]
    if not step then return format_all_buffers() end
    run_source_action(step[1], bufnr, step[2], function() next_step(i + 1) end)
  end
  next_step(1)
end

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    -- NOTE: Remember that Lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    map('<leader>cr', vim.lsp.buf.rename, '[C]ode [R]ename')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Run oxlint and tsc fix-all (and tsc remove-unused-imports) on this buffer, then format every open file buffer.
    if client and fix_all_clients[client.name] then map('<leader>cf', function() fix_all_and_format(event.buf) end, '[C]ode [F]ix all + format all buffers') end

    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    --
    -- This may be unwanted, since they displace some of your code
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Restart all language servers, e.g. after a `git pull` changed files on disk.
-- Reload changed buffers first so the restarted servers re-open them with the new contents.
vim.keymap.set('n', '<leader>cl', function()
  vim.cmd 'checktime'
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    names[client.name] = true
  end
  local list = vim.tbl_keys(names)
  if #list == 0 then return vim.notify('No language servers running', vim.log.levels.WARN) end
  table.sort(list)
  vim.cmd.lsp { args = { 'restart', unpack(list) } }
  vim.notify('Restarted: ' .. table.concat(list, ', '))
end, { desc = '[C]ode: Re-[L]oad buffers language servers' })

-- [[ Inter-file pull diagnostics ]]
-- Neovim only re-pulls diagnostics for the buffer you edited. Servers that declare
-- `interFileDependencies` (e.g. TypeScript 7's `tsc --lsp`) can have other files' diagnostics
-- change too, so re-pull visible buffers after edits and any buffer when it is entered.
do
  local group = vim.api.nvim_create_augroup('lsp-interfile-diagnostics', { clear = true })

  ---@param client vim.lsp.Client
  local function has_interfile_deps(client)
    local provider = client.server_capabilities.diagnosticProvider
    return type(provider) == 'table' and provider.interFileDependencies == true
  end

  ---@param bufnr integer
  ---@param client_id? integer limit to this client
  local function repull(bufnr, client_id)
    if not vim.api.nvim_buf_is_loaded(bufnr) then return end
    for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr, id = client_id, method = 'textDocument/diagnostic' }) do
      if has_interfile_deps(client) then
        vim.lsp.diagnostic._refresh(bufnr, client.id) -- private, but what Neovim itself calls on didChange
      end
    end
  end

  vim.api.nvim_create_autocmd('BufEnter', { group = group, callback = function(ev) repull(ev.buf) end })

  local timer = assert(vim.uv.new_timer())
  vim.api.nvim_create_autocmd('LspNotify', {
    group = group,
    callback = function(ev)
      local method = ev.data.method
      if method ~= 'textDocument/didChange' and method ~= 'textDocument/didSave' then return end
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or not has_interfile_deps(client) then return end
      local changed, client_id = ev.buf, client.id
      timer:stop()
      timer:start(
        500,
        0,
        vim.schedule_wrap(function()
          local seen = { [changed] = true } -- Neovim already re-pulls the edited buffer itself
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if not seen[buf] then
              seen[buf] = true
              repull(buf, client_id)
            end
          end
        end)
      )
    end,
  })
end

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--  See `:help lsp-config` for information about keys and how to configure
---@type table<string, vim.lsp.Config>
local servers = {
  -- clangd = {},
  gopls = {},
  pyright = {},
  -- TypeScript 7 native language server (`tsc --lsp`); prefers a >=7 tsc in node_modules/.bin, else Mason's
  tsc = {},
  oxlint = {
    settings = {
      run = 'onSave', -- lint on write instead of every keystroke
      typeAware = false, -- set explicitly so lspconfig doesn't auto-enable it when tsgolint is found
    },
  },
  --
  -- Some languages (like rust) have entire language plugins that can be useful:
  --    https://github.com/mrcjkb/rustaceanvim
  --
  -- But for many setups, the LSP (`rust_analyzer`) will work just fine
  -- rust_analyzer = {},

  stylua = {}, -- Used to format Lua code

  -- Special Lua Config, as recommended by neovim help docs
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
      client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
          --  See https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.api.nvim_get_runtime_file('', true),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        format = { enable = false }, -- Disable formatting (formatting is done by stylua)
      },
    },
  },
}

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

-- Automatically install LSPs and related tools to stdpath for Neovim
require('mason').setup {}

-- Translates between nvim-lspconfig server names and mason.nvim package names (e.g. lua_ls <-> lua-language-server)
require('mason-lspconfig').setup {
  automatic_enable = false, -- Change this to true if you want to automatically enable servers that are installed manually (e.g. via :Mason / :MasonInstall)
}

-- Ensure the servers and tools above are installed
--
-- To check the current status of installed tools and/or manually install
-- other tools, you can run
--    :Mason
--
-- You can press `g?` for help in this menu.
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  -- You can add other tools here that you want Mason to install
  'prettier', -- Fallback for repos without their own prettier in node_modules (see conform.lua)
})

require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- vim: ts=2 sts=2 sw=2 et
