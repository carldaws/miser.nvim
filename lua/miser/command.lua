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
    complete = function(_, line)
      local parts = vim.split(line, "%s+")
      if #parts <= 2 then
        return subcommands
      end
      return {}
    end,
  })
end

return M
