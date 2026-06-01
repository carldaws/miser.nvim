local mise = require("miser.mise")

local M = {}

M._task_runner = nil

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

return M
