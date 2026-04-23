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

-- Direct lookup
local entry = registry.get("gopls")
assert_not_nil(entry, "gopls should exist")
assert_eq("gopls", entry.lsp, "gopls lsp name")

-- LSP-only entry has no formatter
entry = registry.get("typescript-language-server")
assert_not_nil(entry, "typescript-language-server should exist")
assert_eq("ts_ls", entry.lsp, "ts_ls lsp name")
assert_nil(entry.formatter, "typescript-language-server has no formatter")

-- Formatter-only entry has no lsp
entry = registry.get("prettier")
assert_not_nil(entry, "prettier should exist")
assert_nil(entry.lsp, "prettier has no lsp")
assert_not_nil(entry.formatter, "prettier has formatter")

-- LSP + formatter entry
entry = registry.get("ruff")
assert_not_nil(entry, "ruff should exist")
assert_eq("ruff", entry.lsp, "ruff lsp name")
assert_not_nil(entry.formatter, "ruff has formatter")

-- Backend prefix stripping
entry = registry.get("npm:typescript-language-server")
assert_not_nil(entry, "npm: prefix should be stripped")
assert_eq("ts_ls", entry.lsp, "npm: prefix lookup")

entry = registry.get("pipx:ruff")
assert_not_nil(entry, "pipx: prefix should be stripped")
assert_eq("ruff", entry.lsp, "pipx: prefix lookup")

-- Go module path: match last segment
entry = registry.get("go:golang.org/x/tools/gopls")
assert_not_nil(entry, "go module path should match gopls")
assert_eq("gopls", entry.lsp, "go module path lsp name")

-- No prefix doesn't double-lookup
entry = registry.get("gopls")
assert_not_nil(entry, "no prefix still works")

-- Unknown tool returns nil
entry = registry.get("nonexistent-tool")
assert_nil(entry, "unknown tool returns nil")

-- Unknown tool with prefix returns nil
entry = registry.get("npm:nonexistent-tool")
assert_nil(entry, "unknown prefixed tool returns nil")

-- Merge: override existing
registry.merge({
  ["gopls"] = {
    formatter = {
      filetypes = { "go" },
      cmd = { "gofmt", "-w" },
    },
  },
})
entry = registry.get("gopls")
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
