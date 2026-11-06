--[[

## Lua guide
- :help lua-guide
- (or HTML version): https://neovim.io/doc/user/lua-guide.html

## Help
- "<space>sh" to [s]earch the [h]elp documentation
- :help

## Healthcheck
If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

## Layout
- lua/options.lua               leader keys and vim options
- lua/keymaps.lua               basic keymaps, diagnostics config, basic autocmds
- lua/pack.lua                  vim.pack build hooks
- lua/plugins.lua               loads the plugin modules below, in order
- lua/kickstart/plugins/*.lua   one file per plugin (or group of related plugins)
- lua/custom/plugins/*.lua      your own additions, auto-loaded

--]]

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps & Autocmds ]]
require 'keymaps'

-- [[ Plugin manager build hooks ]]
require 'pack'

-- [[ Configure and install plugins ]]
require 'plugins'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
