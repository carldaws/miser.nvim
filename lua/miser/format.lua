local registry = require("miser.registry")

local M = {}

-- Map of filetype -> formatter cmd, built once from mise tools + registry
M._formatters = {}

function M.setup(tools)
  M._formatters = {}

  local claimed = {}

  for tool_name, _ in pairs(tools) do
    local entry = registry.get(tool_name)
    if entry and entry.formatter then
      for _, ft in ipairs(entry.formatter.filetypes) do
        if not claimed[ft] then
          claimed[ft] = true
          M._formatters[ft] = entry.formatter.cmd
        end
      end
    end
  end

  if not vim.tbl_isempty(M._formatters) then
    M._create_autocmd()
  end

  return M._formatters
end

function M._create_autocmd()
  local group = vim.api.nvim_create_augroup("miser-format", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      local buf = ev.buf
      if vim.b[buf]._miser_formatting then
        return
      end

      local ft = vim.bo[buf].filetype
      local cmd = M._formatters[ft]
      if not cmd then
        return
      end

      local filepath = vim.api.nvim_buf_get_name(buf)
      if filepath == "" then
        return
      end

      vim.b[buf]._miser_formatting = true

      local full_cmd = vim.list_extend({}, cmd)
      table.insert(full_cmd, filepath)

      vim.system(full_cmd, { text = true }, function(result)
        vim.schedule(function()
          vim.b[buf]._miser_formatting = false
          if result.code == 0 then
            vim.cmd("checktime")
          else
            vim.notify(
              "miser: format failed (" .. table.concat(cmd, " ") .. ")\n" .. (result.stderr or ""),
              vim.log.levels.WARN
            )
          end
        end)
      end)
    end,
  })
end

return M
