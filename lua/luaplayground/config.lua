local M = { val = nil }

local defaults = {
  toggle_key = "<F5>",
  auto_run = false,
  init_func = nil,
  max_count = 10000,
  output = {
    virtual_text = true,
    notify = true,
  },
  context = {},
}

M.setup = function(opts)
  vim.validate({
    toggle_key = { opts.toggle_key, "string", true },
    init_func = { opts.init_func, "function", true },
    context = { opts.context, "table", true },
    output = { opts.output, "table", true },
    max_count = { opts.max_count, "number", true },
  })

  if opts.output ~= nil then
    vim.validate({
      ["output.virtual_text"] = { opts.output.virtual_text, "boolean", true },
      ["output.notify"] = { opts.output.notify, "boolean", true },
    })
  end

  M.val = vim.tbl_extend("force", defaults, opts or {})
end

return M
