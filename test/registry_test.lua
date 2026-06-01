local registry = require("miser.registry")
local h = require("test.helpers")

local function snapshot_registry()
  return vim.deepcopy(registry.entries)
end

local function restore_registry(snapshot)
  registry.entries = snapshot
end

-- Exact mise tool names (no prefix stripping)
local entry = registry.get("gem:ruby-lsp")
h.assert_not_nil(entry, "gem:ruby-lsp exists")
h.assert_eq("ruby_lsp", entry.lsp, "ruby-lsp lsp name")
h.assert_nil(entry.formatter, "ruby-lsp has no formatter")

entry = registry.get("gem:rubocop")
h.assert_not_nil(entry, "gem:rubocop exists")
h.assert_eq("rubocop", entry.lsp, "rubocop lsp name")
h.assert_not_nil(entry.formatter, "rubocop has formatter")

entry = registry.get("go:golang.org/x/tools/gopls")
h.assert_not_nil(entry, "go:golang.org/x/tools/gopls exists")
h.assert_eq("gopls", entry.lsp, "gopls lsp name")

-- LSP-only entry has no formatter
entry = registry.get("npm:typescript-language-server")
h.assert_not_nil(entry, "npm:typescript-language-server exists")
h.assert_eq("ts_ls", entry.lsp, "ts_ls lsp name")
h.assert_nil(entry.formatter, "typescript-language-server has no formatter")

-- Scoped npm package
entry = registry.get("npm:@astrojs/language-server")
h.assert_not_nil(entry, "npm:@astrojs/language-server exists")
h.assert_eq("astro", entry.lsp, "astro lsp name")

-- Mise registry short names
entry = registry.get("lua-language-server")
h.assert_not_nil(entry, "lua-language-server exists")
h.assert_eq("lua_ls", entry.lsp, "lua_ls lsp name")

entry = registry.get("ruff")
h.assert_not_nil(entry, "ruff exists")
h.assert_eq("ruff", entry.lsp, "ruff lsp name")
h.assert_not_nil(entry.formatter, "ruff has formatter")

-- Formatter-only entry has no lsp
entry = registry.get("prettier")
h.assert_not_nil(entry, "prettier exists")
h.assert_nil(entry.lsp, "prettier has no lsp")
h.assert_not_nil(entry.formatter, "prettier has formatter")

-- Unknown tool returns nil
h.assert_nil(registry.get("nonexistent-tool"), "unknown tool returns nil")

-- Bare name doesn't match a prefixed key
h.assert_nil(registry.get("rubocop"), "bare rubocop does not match gem:rubocop")

-- Merge: override existing (snapshot + restore so other tests don't see it)
local snapshot = snapshot_registry()
registry.merge({
  ["go:golang.org/x/tools/gopls"] = {
    formatter = {
      filetypes = { "go" },
      cmd = { "gofmt", "-w" },
    },
  },
})
entry = registry.get("go:golang.org/x/tools/gopls")
h.assert_eq("gopls", entry.lsp, "merge preserves existing lsp")
h.assert_not_nil(entry.formatter, "merge adds formatter")
restore_registry(snapshot)

-- Merge: add new
snapshot = snapshot_registry()
registry.merge({ ["custom-tool"] = { lsp = "custom_ls" } })
entry = registry.get("custom-tool")
h.assert_not_nil(entry, "merge adds new entry")
h.assert_eq("custom_ls", entry.lsp, "merge new entry lsp name")
restore_registry(snapshot)

h.report("registry")
