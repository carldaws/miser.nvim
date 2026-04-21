local M = {}

function M.run(on_complete)
  vim.system({ "mise", "trust" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("miser: mise trust failed\n" .. (result.stderr or ""), vim.log.levels.ERROR)
      end
      if on_complete then
        on_complete()
      end
    end)
  end)
end

return M
