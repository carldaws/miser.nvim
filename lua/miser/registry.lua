local M = {}

M.entries = {
  -- LSP-only (configs provided by nvim-lspconfig)
  ["lua-language-server"] = { lsp = "lua_ls" },
  ["ruby-lsp"] = { lsp = "ruby_lsp" },
  ["typescript-language-server"] = { lsp = "ts_ls" },
  ["astro-language-server"] = { lsp = "astro" },
  ["gopls"] = { lsp = "gopls" },

  -- LSP + formatter
  ["rubocop"] = {
    lsp = "rubocop",
    formatter = {
      filetypes = { "ruby" },
      cmd = { "rubocop", "-A", "--stderr" },
    },
  },
  ["ruff"] = {
    lsp = "ruff",
    formatter = {
      filetypes = { "python" },
      cmd = { "ruff", "format" },
    },
  },

  -- Formatter-only
  ["biome"] = {
    formatter = {
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "css" },
      cmd = { "biome", "format", "--write" },
    },
  },
  ["prettier"] = {
    formatter = {
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "css", "html", "json", "yaml", "markdown", "astro" },
      cmd = { "prettier", "--write" },
    },
  },
  ["stylua"] = {
    formatter = {
      filetypes = { "lua" },
      cmd = { "stylua" },
    },
  },
  ["gofumpt"] = {
    formatter = {
      filetypes = { "go" },
      cmd = { "gofumpt", "-w" },
    },
  },
  ["black"] = {
    formatter = {
      filetypes = { "python" },
      cmd = { "black" },
    },
  },
  ["shfmt"] = {
    formatter = {
      filetypes = { "sh", "bash", "zsh" },
      cmd = { "shfmt", "-w" },
    },
  },
}

function M.get(tool_name)
  local entry = M.entries[tool_name]
  if entry then
    return entry
  end
  -- Strip backend prefix (npm:foo → foo, pipx:ruff → ruff)
  local bare_name = tool_name:gsub("^%w+:", "")
  if bare_name ~= tool_name then
    entry = M.entries[bare_name]
    if entry then
      return entry
    end
  end
  -- Match last path segment (go:golang.org/x/tools/gopls → gopls)
  local basename = tool_name:match("[^/]+$")
  if basename and basename ~= tool_name then
    return M.entries[basename]
  end
end

function M.merge(overrides)
  for tool, config in pairs(overrides) do
    if M.entries[tool] then
      M.entries[tool] = vim.tbl_deep_extend("force", M.entries[tool], config)
    else
      M.entries[tool] = config
    end
  end
end

return M
