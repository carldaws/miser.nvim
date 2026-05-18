local M = {}

function M.run()
  vim.system({ "mise", "install" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("miser: mise install failed\n" .. (result.stderr or ""), vim.log.levels.ERROR)
        return
      end
      local miser = require("miser")
      miser.activate(miser._opts)
    end)
  end)
end

return M
