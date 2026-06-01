local mise = require("miser.mise")

local M = {}

M.defaults = {
  auto_install = true,
  auto_format = true,
  auto_lsp = true,
  registry = {},
  task_runner = nil,
}

M.state = {
  tools = {},
  tasks = {},
  configs = {},
  lsps = {},
  formatters = {},
  conflicts = {},
}

M.opts = nil

local path_activated = false

local function activate_path()
  if path_activated then
    return
  end
  local bin_paths = mise.bin_paths()
  if #bin_paths > 0 then
    vim.env.PATH = table.concat(bin_paths, ":") .. ":" .. vim.env.PATH
  end
  path_activated = true
end

function M.activate()
  activate_path()

  M.state.tools = mise.tools()
  M.state.tasks = mise.tasks()
  M.state.configs = mise.configs()

  require("miser.format").refresh(M.state, M.opts)
  require("miser.lsp").refresh(M.state, M.opts)
  require("miser.lsp").setup_format_on_save(M.state, M.opts)
end

function M.install()
  mise.install(function(ok)
    if ok then
      M.activate()
    end
  end)
end

function M.trust()
  mise.trust(function(ok)
    if ok then
      M.activate()
    end
  end)
end

function M.format(buf, opts)
  require("miser.format").run(M.state, buf, opts)
end

function M.show_status()
  require("miser.status").show(M.state)
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.defaults, opts or {})

  if not mise.available() then
    vim.notify("miser: mise not found in PATH", vim.log.levels.ERROR)
    return
  end

  if not vim.tbl_isempty(M.opts.registry) then
    require("miser.registry").merge(M.opts.registry)
  end

  if M.opts.task_runner then
    require("miser.tasks")._task_runner = M.opts.task_runner
  end

  M.activate()

  if M.opts.auto_install then
    M.install()
  end

  require("miser.command").setup()
end

return M
