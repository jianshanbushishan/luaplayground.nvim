
local M = {
  playground = vim.fn.stdpath("data") .. "/playground.lua"
}

M.save_plagroud = function(bufnr)
  if bufnr == -1 then
    return
  end

  local f = io.open(M.playground, "w")
  if f ~= nil then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local len = #lines
    for idx = len, 1, -1 do
      if lines[idx]:match("(%w+)") ~= nil then
        break
      end

      table.remove(lines, idx)
    end

    for _, line in ipairs(lines) do
      f:write(line .. "\n")
    end
    f:close()
  end
end

M.load_playgroud = function(bufnr)
    local lines = {}

    local f = io.open(playground, "r")
    if f == nil then
      f = io.open(playground, "w")
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

return M
