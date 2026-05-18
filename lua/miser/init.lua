local M = {}

M.defaults = {
  auto_install = true,
  auto_format = true,
  auto_lsp = true,
  registry = {},
  task_runner = nil,
}

M._state = {
  tools = {},
  enabled_lsps = {},
  formatters = {},
}

M._path_activated = false

function M.activate(opts)
  if not M._path_activated then
    local bin_paths = vim.fn.systemlist({ "mise", "bin-paths" })
    if #bin_paths > 0 then
      vim.env.PATH = table.concat(bin_paths, ":") .. ":" .. vim.env.PATH
    end
    M._path_activated = true
  end

  local json = vim.fn.system({ "mise", "ls", "--current", "--json" })
  local ok, tools = pcall(vim.json.decode, json)
  if not ok or not tools then
    tools = {}
  end

  M._state.tools = tools

  if opts.auto_lsp then
    M._state.enabled_lsps = require("miser.lsp").setup(tools)
  end

  M._state.formatters = require("miser.format").setup(tools, opts.auto_format)
end

function M.show_status()
  require("miser.status").show(M._state)
end

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})
  M._opts = opts

  if vim.fn.executable("mise") == 0 then
    vim.notify("miser: mise not found in PATH", vim.log.levels.ERROR)
    return
  end

  local registry = require("miser.registry")
  if not vim.tbl_isempty(opts.registry) then
    registry.merge(opts.registry)
  end

  if opts.task_runner then
    require("miser.tasks")._task_runner = opts.task_runner
  end

  M.activate(opts)

  if opts.auto_install then
    require("miser.install").run()
  end

  if opts.auto_lsp then
    require("miser.lsp").setup_format_on_save()
  end

  vim.api.nvim_create_user_command("Miser", function(cmd_opts)
    local args = cmd_opts.fargs
    local subcmd = args[1]

    if subcmd == "run" then
      local task_name = args[2]
      if not task_name then
        vim.notify("miser: usage: Miser run <task> [args...]", vim.log.levels.WARN)
        return
      end
      require("miser.tasks").run(task_name, vim.list_slice(args, 3))
    elseif subcmd == "trust" then
      require("miser.trust").run(function()
        M.activate(M._opts)
      end)
    elseif subcmd == "install" then
      require("miser.install").run()
    elseif subcmd == "status" then
      M.show_status()
    elseif subcmd == "format" then
      local bufnr = vim.api.nvim_get_current_buf()
      if vim.bo[bufnr].modified then
        vim.cmd("write")
      end
      require("miser.format").run(bufnr, { notify = true })
    else
      vim.notify(
        "miser: unknown command '" .. (subcmd or "") .. "'\nUsage: Miser status | run <task> | install | trust | format",
        vim.log.levels.WARN
      )
    end
  end, {
    nargs = "+",
    complete = function(_, line)
      local parts = vim.split(line, "%s+")
      if #parts <= 2 then
        return { "install", "run", "status", "trust", "format" }
      end
      return {}
    end,
  })
end

return M
