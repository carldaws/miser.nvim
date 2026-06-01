local mise = require("miser.mise")

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

M._opts = nil

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

function M.activate(opts)
  activate_path()

  M._state.tools = mise.tools()

  if opts.auto_lsp then
    M._state.enabled_lsps = require("miser.lsp").setup(M._state.tools)
  end

  M._state.formatters = require("miser.format").setup(M._state.tools, opts.auto_format)
end

function M.install()
  mise.install(function(ok)
    if ok then
      M.activate(M._opts)
    end
  end)
end

function M.trust()
  mise.trust(function(ok)
    if ok then
      M.activate(M._opts)
    end
  end)
end

function M.format(buf, opts)
  require("miser.format").run(buf, opts)
end

function M.show_status()
  require("miser.status").show(M._state)
end

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})
  M._opts = opts

  if not mise.available() then
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
    M.install()
  end

  if opts.auto_lsp then
    require("miser.lsp").setup_format_on_save()
  end

  require("miser.command").setup()
end

return M
