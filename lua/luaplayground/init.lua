local M = {}

M.setup = function(opts)
  local config = require("luaplayground.config")
  config.setup(opts)

  local ui = require("luaplayground.ui")
  vim.keymap.set("n", config.val.toggle_key, ui.toggle)
end

return M
