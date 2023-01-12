local M = { val = nil }

local defaults = {
  toggle_key = "<F5>",
  init_func = nil,
  max_count = 10000,
  context = {
    the_answer = 42,
    shout = function(str)
      return (str:upper() .. "!")
    end,
  },
}

M.setup = function(opts)
  vim.validate({
    toggle_key = { opts.toggle_key, "string", true },
    init_func = { opts.init_func, "function", true },
    context = { opts.context, "table", true },
  })

  M.val = vim.tbl_extend("force", defaults, opts or {})
end

return M
