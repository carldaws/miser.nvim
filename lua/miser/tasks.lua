local M = {}

function M.list(callback)
  vim.system({ "mise", "task", "ls", "--json" }, { text = true }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        callback({})
      end)
      return
    end

    local ok, tasks = pcall(vim.json.decode, result.stdout)
    if not ok or not tasks then
      vim.schedule(function()
        callback({})
      end)
      return
    end

    vim.schedule(function()
      callback(tasks)
    end)
  end)
end

local function default_runner(cmd)
  vim.cmd("botright new | resize 15")
  vim.fn.termopen(vim.split(cmd, " "))
end

function M.run(task_name, args, opts)
  opts = opts or {}
  local parts = { "mise", "run", task_name }
  if args and #args > 0 then
    table.insert(parts, "--")
    vim.list_extend(parts, args)
  end

  local cmd = table.concat(parts, " ")
  local runner = opts.task_runner or M._task_runner or default_runner

  vim.schedule(function()
    runner(cmd)
  end)
end

return M
