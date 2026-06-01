local mise = require("miser.mise")

local M = {}

function M.check()
  vim.health.start("miser")

  if not mise.available() then
    vim.health.error("mise not found in PATH", { "Install mise: https://mise.jdx.dev/" })
    return
  end
  vim.health.ok("mise found: " .. mise.version())

  local miser_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  local lsp_dir = miser_root .. "/deps/nvim-lspconfig/lsp"
  if vim.fn.isdirectory(lsp_dir) == 1 then
    vim.health.ok("nvim-lspconfig submodule found")
  else
    vim.health.error("nvim-lspconfig submodule missing", {
      "Run: cd " .. miser_root .. " && git submodule update --init",
    })
  end

  local toml = vim.fn.getcwd() .. "/mise.toml"
  if vim.fn.filereadable(toml) == 1 then
    vim.health.ok("mise.toml found in project")
  else
    vim.health.info("No mise.toml in current directory")
  end

  local tools = mise.tools()
  local registry = require("miser.registry")
  local found_lsp = 0
  local found_fmt = 0
  for tool_name, _ in pairs(tools) do
    local entry = registry.get(tool_name)
    if entry then
      if entry.lsp then
        found_lsp = found_lsp + 1
      end
      if entry.formatter then
        found_fmt = found_fmt + 1
      end
    end
  end
  vim.health.ok(found_lsp .. " LSP server(s) and " .. found_fmt .. " formatter(s) matched from registry")

  local clients = vim.lsp.get_clients()
  if #clients > 0 then
    for _, client in ipairs(clients) do
      vim.health.ok("LSP running: " .. client.name)
    end
  else
    vim.health.info("No LSP clients currently running")
  end
end

return M
