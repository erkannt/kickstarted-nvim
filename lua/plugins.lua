-- Load plugin modules in order.

require 'kickstart.plugins.guess-indent'
require 'kickstart.plugins.gitsigns'
require 'kickstart.plugins.which-key'
require 'kickstart.plugins.colorscheme'
require 'kickstart.plugins.mini'
require 'kickstart.plugins.telescope'
require 'kickstart.plugins.lspconfig'
require 'kickstart.plugins.conform'
require 'kickstart.plugins.blink-cmp'
require 'kickstart.plugins.treesitter'

-- Optional example plugins shipped with kickstart.
--  Uncomment any of the lines below to enable them (you will need to restart nvim).
--
-- require 'kickstart.plugins.debug'
-- require 'kickstart.plugins.indent_line'
-- require 'kickstart.plugins.lint'
-- require 'kickstart.plugins.autopairs'
require 'kickstart.plugins.neo-tree'

-- Your own plugins live in `lua/custom/plugins/*.lua` and are loaded automatically.
--
-- `custom.plugins` loads files from that directory in unspecified order. If plugins
-- depend on each other, keep them in the same file and put their `vim.pack.add()`
-- and `setup()` calls in the required order, or require them explicitly here instead.
require 'custom.plugins'

-- vim: ts=2 sts=2 sw=2 et
