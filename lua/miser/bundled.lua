local M = {}

function M.list(callback)
  vim.system({ "bundle", "list", "--name-only" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback({})
        return
      end
      local gems = {}
      for line in result.stdout:gmatch("[^\n]+") do
        gems[vim.trim(line)] = true
      end
      callback(gems)
    end)
  end)
end

return M
