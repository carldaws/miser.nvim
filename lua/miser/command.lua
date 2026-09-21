local M = {}

local subcommands = { "format", "install", "run", "status", "trust" }

function M.setup()
  vim.api.nvim_create_user_command("Miser", function(cmd_opts)
    local args = cmd_opts.fargs
    local subcmd = args[1]
    local miser = require("miser")

    if subcmd == "install" then
      miser.install()
    elseif subcmd == "trust" then
      miser.trust()
    elseif subcmd == "status" then
      miser.show_status()
    elseif subcmd == "format" then
      local bufnr = vim.api.nvim_get_current_buf()
      if vim.bo[bufnr].modified then
        vim.cmd("write")
      end
      miser.format(bufnr, { notify = true })
    elseif subcmd == "run" then
      local task_name = args[2]
      if not task_name then
        vim.notify("miser: usage: Miser run <task> [args...]", vim.log.levels.WARN)
        return
      end
      require("miser.tasks").run(task_name, vim.list_slice(args, 3))
    else
      vim.notify(
        "miser: unknown command '" .. (subcmd or "") .. "'\nUsage: Miser " .. table.concat(subcommands, " | "),
        vim.log.levels.WARN
      )
    end
  end, {
    nargs = "+",
    complete = function(arg_lead, line)
      local parts = vim.split(line, "%s+")
      local candidates = {}
      if #parts <= 2 then
        candidates = subcommands
      elseif parts[2] == "run" and #parts == 3 then
        candidates = vim.tbl_map(function(task)
          return task.name
        end, require("miser.tasks").list())
      end
      return vim.tbl_filter(function(candidate)
        return vim.startswith(candidate, arg_lead)
      end, candidates)
    end,
  })
end

return M
