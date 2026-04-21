local M = {}

function M.run(on_complete)
  local toml = vim.fn.getcwd() .. "/mise.toml"
  if vim.fn.filereadable(toml) == 0 then
    if on_complete then
      on_complete()
    end
    return
  end

  vim.system({ "mise", "install" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("miser: mise install failed\n" .. (result.stderr or ""), vim.log.levels.ERROR)
      end
      if on_complete then
        on_complete()
      end
    end)
  end)
end

return M
