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

function M.install()
  require("miser.install").run()
end

function M.trust()
  require("miser.trust").run(function()
    M.activate(M._opts)
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

  require("miser.command").setup()
end

return M
