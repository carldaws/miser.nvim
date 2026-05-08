local lsp = require("miser.lsp")
local registry = require("miser.registry")

local failures = 0

local function assert_eq(expected, actual, msg)
  if expected ~= actual then
    failures = failures + 1
    print("FAIL: " .. msg .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
  end
end

local function assert_not_nil(actual, msg)
  if actual == nil then
    failures = failures + 1
    print("FAIL: " .. msg .. " (expected non-nil)")
  end
end

-- Stub vim.lsp.config and vim.lsp.enable so we can run without a real LSP client
local configured = {}
local enabled = {}
vim.lsp.config = function(name, config)
  configured[name] = config
end
vim.lsp.enable = function(name)
  table.insert(enabled, name)
end

-- astro.lua requires lspconfig.util — this will error if the submodule
-- lua/ directory isn't on the rtp
local result = lsp.setup({
  ["npm:@astrojs/language-server"] = { { version = "2.0.0" } },
})

assert_not_nil(configured["astro"], "astro config should be loaded")
assert_not_nil(require("lspconfig.util"), "lspconfig.util should be requireable after setup")

-- List of LSPs: a single tool can map to multiple LSP servers
configured = {}
enabled = {}
registry.merge({
  ["npm:vscode-langservers-extracted"] = {
    lsp = { "html", "cssls", "jsonls" },
  },
})

result = lsp.setup({
  ["npm:vscode-langservers-extracted"] = { { version = "4.0.0" } },
})

assert_not_nil(configured["html"], "html config should be loaded from lsp list")
assert_not_nil(configured["cssls"], "cssls config should be loaded from lsp list")
assert_not_nil(configured["jsonls"], "jsonls config should be loaded from lsp list")
assert_eq(3, #enabled, "all three LSPs from list should be enabled")

-- Registry entry config is deep-merged over the bundled lspconfig
configured = {}
enabled = {}
registry.merge({
  ["lua-language-server"] = {
    config = {
      settings = { Lua = { workspace = { library = { "/some/path" } } } },
    },
  },
})

result = lsp.setup({
  ["lua-language-server"] = { { version = "3.18.0" } },
})

assert_not_nil(configured["lua_ls"], "lua_ls config should be loaded")
assert_eq(
  "/some/path",
  configured["lua_ls"].settings.Lua.workspace.library[1],
  "registry config should be merged into lsp config"
)

-- Per-LSP overrides for multi-LSP entries
configured = {}
enabled = {}
registry.merge({
  ["npm:vscode-langservers-extracted"] = {
    lsp = { "html", "cssls", "jsonls" },
    config = {
      cssls = { settings = { css = { validate = false } } },
    },
  },
})

result = lsp.setup({
  ["npm:vscode-langservers-extracted"] = { { version = "4.0.0" } },
})

assert_eq(
  false,
  configured["cssls"].settings.css.validate,
  "per-LSP override should apply only to the named server"
)
assert_eq(
  nil,
  configured["html"].settings and configured["html"].settings.css,
  "non-overridden server should not receive another server's settings"
)

if failures == 0 then
  print("OK: all lsp tests passed")
else
  print(failures .. " test(s) failed")
  vim.cmd("cquit 1")
end
