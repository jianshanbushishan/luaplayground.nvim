local M = {}

local defaults = {
  toggle_key = "<F5>", 
  init_func = nil,
  context = nil,
}

M.setup = function(opts)
  local config = require("luaplayground.config")
  config.setup(opts)

  local ui = require("luaplayground.ui")
  vim.keymap.set("n", config.toggle_key, ui.toggle)
end

return M
