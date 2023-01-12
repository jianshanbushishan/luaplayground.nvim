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

local function parse_error(msg)
  return msg:match("%[string.*%]:(.*)")
end

M.run = function(bufnr)
  local lines = M.get_buf_lines(bufnr)
  if lines == nil then
    return
  end

  local f, error_msg = loadstring(table.concat(lines, "\n"))
  if not f then
    local _, msg = parse_error(error_msg)
    vim.notify(msg, vim.log.levels.ERROR, { title = "lua playground" })
    return
  end

  local context = {}
  context.p = M.print
  context.print = M.print

  M.output = {}
  setmetatable(context, { __index = _G })
  setfenv(f, context)

  local max_count = require("luaplayground.config").val.max_count
  local success, result = pcall(function()
    debug.sethook(function()
      error("LuapadTimeoutError")
    end, "", max_count)
    f()
  end)

  local ui = require("luaplayground.ui")
  if not success and result ~= nil then
    if result:find("LuapadTimeoutError") then
      vim.notify("run timeout", vim.log.levels.WARN, { title = "lua playground" })
    else
      ui.show_error(result)
    end
  end

  ui.show_output(M.output)
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
  end

  local line = debug.traceback("", 3):match("^.-]:(%d-):")
  if not line then
    return
  end

  line = tonumber(line)
  if line == nil then
    return
  end

  if not M.output[line] then
    M.output[line] = {}
  end
  table.insert(M.output[line], str)
end

return M
