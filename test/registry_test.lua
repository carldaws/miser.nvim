local registry = require("miser.registry")

local failures = 0

local function assert_eq(expected, actual, msg)
  if expected ~= actual then
    failures = failures + 1
    print("FAIL: " .. msg .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
  end
end

local function assert_nil(actual, msg)
  if actual ~= nil then
    failures = failures + 1
    print("FAIL: " .. msg .. " (expected nil, got " .. tostring(actual) .. ")")
  end
end

local function assert_not_nil(actual, msg)
  if actual == nil then
    failures = failures + 1
    print("FAIL: " .. msg .. " (expected non-nil)")
  end
end

-- Exact mise tool names (no prefix stripping)
local entry = registry.get("gem:ruby-lsp")
assert_not_nil(entry, "gem:ruby-lsp should exist")
assert_eq("ruby_lsp", entry.lsp, "ruby-lsp lsp name")
assert_nil(entry.formatter, "ruby-lsp has no formatter")

entry = registry.get("gem:rubocop")
assert_not_nil(entry, "gem:rubocop should exist")
assert_eq("rubocop", entry.lsp, "rubocop lsp name")
assert_not_nil(entry.formatter, "rubocop has formatter")

entry = registry.get("go:golang.org/x/tools/gopls")
assert_not_nil(entry, "go:golang.org/x/tools/gopls should exist")
assert_eq("gopls", entry.lsp, "gopls lsp name")

-- LSP-only entry has no formatter
entry = registry.get("npm:typescript-language-server")
assert_not_nil(entry, "npm:typescript-language-server should exist")
assert_eq("ts_ls", entry.lsp, "ts_ls lsp name")
assert_nil(entry.formatter, "typescript-language-server has no formatter")

-- Scoped npm package
entry = registry.get("npm:@astrojs/language-server")
assert_not_nil(entry, "npm:@astrojs/language-server should exist")
assert_eq("astro", entry.lsp, "astro lsp name")

-- Mise registry short names (no prefix)
entry = registry.get("lua-language-server")
assert_not_nil(entry, "lua-language-server should exist")
assert_eq("lua_ls", entry.lsp, "lua_ls lsp name")

entry = registry.get("ruff")
assert_not_nil(entry, "ruff should exist")
assert_eq("ruff", entry.lsp, "ruff lsp name")
assert_not_nil(entry.formatter, "ruff has formatter")

-- Formatter-only entry has no lsp
entry = registry.get("prettier")
assert_not_nil(entry, "prettier should exist")
assert_nil(entry.lsp, "prettier has no lsp")
assert_not_nil(entry.formatter, "prettier has formatter")

-- Unknown tool returns nil
entry = registry.get("nonexistent-tool")
assert_nil(entry, "unknown tool returns nil")

-- Bare name doesn't match when full mise key is required
entry = registry.get("rubocop")
assert_nil(entry, "bare rubocop should not match (need gem:rubocop)")

-- Merge: override existing
registry.merge({
  ["go:golang.org/x/tools/gopls"] = {
    formatter = {
      filetypes = { "go" },
      cmd = { "gofmt", "-w" },
    },
  },
})
entry = registry.get("go:golang.org/x/tools/gopls")
assert_eq("gopls", entry.lsp, "merge preserves existing lsp")
assert_not_nil(entry.formatter, "merge adds formatter")

-- Merge: add new
registry.merge({
  ["custom-tool"] = {
    lsp = "custom_ls",
  },
})
entry = registry.get("custom-tool")
assert_not_nil(entry, "merge adds new entry")
assert_eq("custom_ls", entry.lsp, "merge new entry lsp name")

if failures == 0 then
  print("OK: all registry tests passed")
else
  print(failures .. " test(s) failed")
  vim.cmd("cquit 1")
end
