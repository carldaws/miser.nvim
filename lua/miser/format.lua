local registry = require("miser.registry")

local M = {}

function M.refresh(state, opts)
  state.formatters = {}
  state.conflicts = {}

  local claims = {}
  for tool_name in pairs(state.tools) do
    local entry = registry.get(tool_name)
    if entry and entry.formatter then
      for _, ft in ipairs(entry.formatter.filetypes) do
        claims[ft] = claims[ft] or {}
        table.insert(claims[ft], { tool = tool_name, cmd = entry.formatter.cmd })
      end
    end
  end

  for ft, list in pairs(claims) do
    if #list == 1 then
      state.formatters[ft] = list[1].cmd
    else
      local tools = vim.tbl_map(function(c)
        return c.tool
      end, list)
      table.sort(tools)
      table.insert(state.conflicts, { filetype = ft, tools = tools })
    end
  end

  for _, c in ipairs(state.conflicts) do
    vim.notify(
      string.format(
        "miser: multiple formatters claim '%s' (%s) — pick one in mise.toml",
        c.filetype,
        table.concat(c.tools, ", ")
      ),
      vim.log.levels.WARN
    )
  end

  local group = vim.api.nvim_create_augroup("miser-format", { clear = true })
  if opts.auto_format and not vim.tbl_isempty(state.formatters) then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      callback = function(ev)
        M.run(state, ev.buf)
      end,
    })
  end
end

function M.run(state, buf, opts)
  opts = opts or {}

  if vim.b[buf]._miser_formatting then
    return
  end

  local ft = vim.bo[buf].filetype
  local cmd = state.formatters[ft]
  if not cmd then
    if opts.notify then
      vim.notify("miser: no formatter for filetype '" .. ft .. "'", vim.log.levels.INFO)
    end
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
end

return M
