local M = {
  playground = vim.fn.stdpath("data") .. "/playground.lua",
}

M.get_buf_lines = function(bufnr)
  if bufnr == -1 or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local len = #lines
  for idx = len, 1, -1 do
    if lines[idx]:match("(%w+)") ~= nil then
      break
    end

    table.remove(lines, idx)
  end
  return lines
end

M.save_plagroud = function(bufnr)
  local lines = M.get_buf_lines(bufnr)
  if lines == nil then
    return
  end

  local f = io.open(M.playground, "w")
  if f ~= nil then
    for _, line in ipairs(lines) do
      f:write(line .. "\n")
    end
    f:close()
  end
end

M.load_playgroud = function(bufnr)
  local lines = {}

  local f = io.open(M.playground, "r")
  if f == nil then
    f = io.open(M.playground, "w")
  else
    for line in f:lines("*l") do
      table.insert(lines, line)
    end
  end
  if f ~= nil then
    f:close()
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
end

M.run = function(bufnr, namespace)
  local lines = M.get_buf_lines(bufnr)
  if lines == nil then
    return
  end

  local ui = require("luaplayground.ui")
  local config = require("luaplayground.config").val
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  local func, error_msg = loadstring(table.concat(lines, "\n"))
  if func == nil then
    ui.show_error(error_msg)
    return
  end

  local context = {}
  context = vim.tbl_extend("force", context, config.context)
  context.print = M.print

  M.output = {}
  M.output_all = {}
  setmetatable(context, { __index = _G })
  setfenv(func, context)

  local max_count = config.max_count
  local success, result = pcall(function()
    debug.sethook(function()
      error("LuapadTimeoutError")
    end, "", max_count)
    func()
  end)
  debug.sethook()

  if not success then
    if result ~= nil then
      if result:find("LuapadTimeoutError") then
        vim.notify("run timeout", vim.log.levels.WARN, { title = "lua playground error" })
      else
        ui.show_error(result)
      end
    end
  else
    if config.output.notify and #M.output_all > 0 then
      local output = table.concat(M.output_all, "\n")
      vim.notify(output, vim.log.levels.INFO, { title = "lua playground output" })
    end
  end

  local count = vim.tbl_count(M.output)
  if config.output.virtual_text and count > 0 then
    ui.show_output(M.output)
  end
end

function M.print(...)
  local size = select("#", ...)
  if size == 0 then
    return
  end

  local args = { ... }
  local str = {}

  for i = 1, size do
    table.insert(str, tostring(vim.inspect(args[i])))
    local len = #M.output_all
    if len < 30 then
      table.insert(M.output_all, vim.inspect(args[i]))
    elseif len == 30 then
      table.insert(M.output_all, "and more ...")
    end
  end

  local stack = debug.traceback()
  local line = stack:match("^.-]:(%d-):")
  if not line then
    return
  end

  line = tonumber(line)
  if line == nil then
    return
  end

  if M.output[line] == nil then
    M.output[line] = {}
  end
  local len = #M.output[line]
  if len < 5 then
    table.insert(M.output[line], str)
  elseif len == 5 then
    table.insert(M.output[line], "...")
  end
end

return M
