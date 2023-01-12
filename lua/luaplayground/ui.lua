local M = {
  M.bufnr = -1,
  M.winnr = -1,
  pos = {},
}

M.set_keymap = function()
  local map_opts = { buffer = M.bufnr, silent = true }
  vim.api.nvim_buf_set_keymap(
    "n",
    "q",
    M.close,
    map_opts
  )
  vim.keymap.set(
    {"n","i""},
    "<c-l>",
    M.clean,
    map_opts
  )
end

M.create = function()
  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)
  local offset = { 5, 35 }
  M.pos = {
    relative = "win",
    row = offset[1],
    col = offset[2],
    width = width - 2 * offset[2],
    height = height - 2 * offset[1],
  }

  M.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(M.bufnr, "filetype", "lua")
  M.winnr = vim.api.nvim_open_win(M.bufnr, true, pos)
  require("luaplayground.util").load_playgroud(M.bufnr)

  M.set_keymap()
  M.set_autocmd()
  local config = require("luaplayground.config").val
  if config.init ~= nil then
    config.init()
  end

  vim.cmd("LspStart")
end

M.set_autocmd = function()
    vim.api.nvim_create_autocmd("VimLeavePre", {
      pattern = "*",
      callback = function ()
        require("luaplayground.util").save_plagroud(M.bufnr)
      end,
    })

    local win_enter_aucmd 
    win_enter_aucmd = vim.api.nvim_create_autocmd({ "WinEnter" }, {
        pattern = "*",
        callback = function()
            local buftype = vim.api.nvim_buf_get_option(0, "buftype")
            if buftype ~= "prompt" and buftype ~= "nofile" then
                vim.schedule(CloseLuapad)
                vim.api.nvim_del_autocmd(win_enter_aucmd)
            end
        end,
    })

    require("luapad").attach()
end

M.clean = function()
  vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, {})
end

M.close = function()
  if M.winnr == -1 then
    return
  end

  local clients = vim.lsp.get_active_clients({M.bufnr = M.bufnr})
  for _, client in ipairs(clients) do
    client.stop()
  end

  require("luapad").detach()
  save_plagroud()

  vim.api.nvim_win_close(M.winnr, true)
  vim.keymap.set({ "n", "x" }, "<F5>", toggle)
  M.winnr = -1
  M.bufnr = -1
end

M.toggle = function()
  if M.winnr == -1 then
    M.create()
  else
    if vim.api.nvim_win_is_valid(M.winnr) then
      vim.api.nvim_win_hide(M.winnr)
      M.winnr = -1
    else
      M.winnr = vim.api.nvim_open_win(M.bufnr, true, pos)
    end
  end
end

return M
