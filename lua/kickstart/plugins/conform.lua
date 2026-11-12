local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Formatting ]]
vim.pack.add { gh 'stevearc/conform.nvim' }
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- Escape hatch: skip format on save in repos that have a `.no-format-on-save`
    -- file at their root (e.g. projects whose style differs from the formatter's).
    -- Manual formatting with <leader>f still works there.
    local root = vim.fs.root(bufnr, '.git')
    if root and vim.uv.fs_stat(vim.fs.joinpath(root, '.no-format-on-save')) then return nil end
    return { timeout_ms = 500 }
  end,
  default_format_opts = {
    lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
  },
  -- You can also specify external formatters in here.
  formatters_by_ft = {
    -- Prettier (via the prettierd daemon) for web files, but only in projects that
    -- configure prettier (see `formatters.prettierd` below). Elsewhere these fall back to LSP formatting.
    javascript = { 'prettierd' },
    javascriptreact = { 'prettierd' },
    typescript = { 'prettierd' },
    typescriptreact = { 'prettierd' },
    json = { 'prettierd' },
    jsonc = { 'prettierd' },
    css = { 'prettierd' },
    scss = { 'prettierd' },
    html = { 'prettierd' },
    yaml = { 'prettierd' },
    markdown = { 'prettierd' },
    -- rust = { 'rustfmt' },
    -- Conform can also run multiple formatters sequentially
    -- python = { "isort", "black" },
    --
    -- You can use 'stop_after_first' to run the first available formatter from the list
    -- javascript = { "prettierd", "prettier", stop_after_first = true },
  },
  formatters = {
    -- Only run when a prettier config (.prettierrc*, prettier.config.*, or a "prettier"
    -- key in package.json) is found. prettierd uses the project's own prettier (and
    -- plugins) from node_modules if present, otherwise its bundled one.
    prettierd = { require_cwd = true },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

-- vim: ts=2 sts=2 sw=2 et
