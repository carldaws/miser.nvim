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

function M.run(task_name, args)
  local cmd = { "mise", "run", task_name }
  if args and #args > 0 then
    table.insert(cmd, "--")
    vim.list_extend(cmd, args)
  end

  vim.schedule(function()
    vim.cmd("botright new | resize 15")
    vim.fn.termopen(cmd)
  end)
end

return M
