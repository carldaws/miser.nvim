local mise = require("miser.mise")

local M = {}

M._task_runner = nil
M._bound_keymaps = {}

local function default_runner(cmd)
  vim.cmd("botright new | resize 15")
  vim.fn.jobstart(cmd, { term = true })
end

function M.list()
  return require("miser").state.tasks
end

function M.run(name, args, opts)
  opts = opts or {}
  local cmd = mise.task_cmd(name, args)
  local runner = opts.task_runner or M._task_runner or default_runner
  vim.schedule(function()
    runner(cmd)
  end)
end

function M.refresh_keymaps(state, opts)
  for _, lhs in ipairs(M._bound_keymaps) do
    pcall(vim.keymap.del, "n", lhs)
  end
  M._bound_keymaps = {}

  if not opts.task_keymaps.enabled then
    return
  end

  local prefix = opts.task_keymaps.prefix
  for _, task in ipairs(state.tasks) do
    for _, alias in ipairs(task.aliases or {}) do
      local lhs = prefix .. alias
      vim.keymap.set("n", lhs, function()
        M.run(task.name)
      end, { desc = "miser task: " .. task.name })
      table.insert(M._bound_keymaps, lhs)
    end
  end
end

return M
