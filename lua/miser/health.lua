local M = {}

function M.check()
  vim.health.start("miser")

  -- Check mise
  if vim.fn.executable("mise") == 1 then
    local version = vim.fn.system({ "mise", "--version" }):gsub("\n", "")
    vim.health.ok("mise found: " .. version)
  else
    vim.health.error("mise not found in PATH", { "Install mise: https://mise.jdx.dev/" })
    return
  end

  -- Check lspconfig submodule
  local miser_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  local lsp_dir = miser_root .. "/deps/nvim-lspconfig/lsp"
  if vim.fn.isdirectory(lsp_dir) == 1 then
    vim.health.ok("nvim-lspconfig submodule found")
  else
    vim.health.error("nvim-lspconfig submodule missing", {
      "Run: cd " .. miser_root .. " && git submodule update --init",
    })
  end

  -- Check mise.toml
  local toml = vim.fn.getcwd() .. "/mise.toml"
  if vim.fn.filereadable(toml) == 1 then
    vim.health.ok("mise.toml found in project")
  else
    vim.health.info("No mise.toml in current directory")
  end

  -- Check tools
  local json = vim.fn.system({ "mise", "ls", "--current", "--json" })
  local ok, tools = pcall(vim.json.decode, json)
  if ok and tools then
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
  end

  -- Check active LSP clients
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
