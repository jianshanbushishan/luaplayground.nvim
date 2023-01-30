local M = {
  bufnr = -1,
  winnr = -1,
  pos = {},
  namespace = vim.api.nvim_create_namespace("luaplayground"),
}

M.set_keymap = function()
  local map_opts = { buffer = M.bufnr, silent = true }
  vim.keymap.set("n", "q", M.close, map_opts)
  vim.keymap.set({ "n", "i" }, "<c-l>", M.clean, map_opts)
  vim.keymap.set("n", "R", function()
    require("luaplayground.util").run(M.bufnr, M.namespace)
  end, map_opts)
end

M.create = function()
  local offset = { 5, 35 }
  local width = vim.api.nvim_win_get_width(0) - 2 * offset[2]
  local height = vim.api.nvim_win_get_height(0) - 2 * offset[1]

  if width < 50 then
    width = 50
  end
  if height < 20 then
    height = 20
  end

  M.pos = {
    relative = "win",
    row = offset[1],
    col = offset[2],
    width = width,
    height = height,
  }

  M.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(M.bufnr, "filetype", "lua")
  M.winnr = vim.api.nvim_open_win(M.bufnr, true, M.pos)
  require("luaplayground.util").load_playgroud(M.bufnr)

  M.set_keymap()
  M.set_autocmd()
  local config = require("luaplayground.config").val
  if config.init_func ~= nil then
    config.init_func()
  end

  vim.cmd("LspStart")
end

M.set_autocmd = function()
  local config = require("luaplayground.config").val
  if config.auto_run then
    vim.api.nvim_create_autocmd("InsertLeave", {
      callback = function()
        require("luaplayground.util").run(M.bufnr, M.namespace)
      end,
      buffer = M.bufnr,
    })
  end

  vim.api.nvim_create_autocmd("InsertEnter", {
    callback = function()
      vim.api.nvim_buf_clear_namespace(M.bufnr, M.namespace, 0, -1)
    end,
    buffer = M.bufnr,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    pattern = "*",
    callback = function()
      require("luaplayground.util").save_plagroud(M.bufnr)
    end,
  })

  local win_enter_aucmd
  win_enter_aucmd = vim.api.nvim_create_autocmd({ "WinEnter" }, {
    pattern = "*",
    callback = function()
      local buftype = vim.api.nvim_buf_get_option(0, "buftype")
      if buftype ~= "prompt" and buftype ~= "nofile" then
        vim.schedule(M.close)
        vim.api.nvim_del_autocmd(win_enter_aucmd)
      end
    end,
  })
end

M.clean = function()
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, {})
end

M.close = function()
  if M.winnr == -1 then
    return
  end

  local clients = vim.lsp.get_active_clients({ bufnr = M.bufnr })
  for _, client in ipairs(clients) do
    client.stop()
  end

  require("luaplayground.util").save_plagroud(M.bufnr)

  vim.api.nvim_win_close(M.winnr, true)
  vim.keymap.set({ "n", "x" }, "<F5>", M.toggle)
  M.winnr = -1
  M.bufnr = -1
end

M.toggle = function()
  if M.bufnr == -1 then
    M.create()
  else
    if vim.api.nvim_win_is_valid(M.winnr) then
      vim.api.nvim_win_hide(M.winnr)
      M.winnr = -1
    else
      M.winnr = vim.api.nvim_open_win(M.bufnr, true, M.pos)
    end
  end
end

M.add_virtual_text = function(line, str, color)
  vim.api.nvim_buf_set_virtual_text(
    M.bufnr,
    M.namespace,
    line,
    { { tostring(str), color } },
    {}
  )
end

M.show_output = function(output)
  for line, msg in pairs(output) do
    local ret = vim.tbl_flatten(msg)
    local text = table.concat(ret, " | ")
    M.add_virtual_text(line - 1, text, "Comment")
  end
end

M.show_error = function(msg)
  local config = require("luaplayground.config").val
  local line, error = msg:match("%[string.*%]:(%d+):%s+(.*)")
  if config.output.virtual_text then
    local error_msg = "<== " .. error
    M.add_virtual_text(line - 1, error_msg, "Error")
  else
    local error_msg = "line " .. tostring(line) .. ": " .. error
    vim.notify(error_msg, vim.log.levels.ERROR, { title = "lua playground error" })
  end
end

return M
