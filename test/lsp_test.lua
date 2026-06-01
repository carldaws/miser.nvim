local lsp = require("miser.lsp")
local registry = require("miser.registry")
local h = require("test.helpers")

local configured = {}
local enabled = {}
vim.lsp.config = function(name, config)
  configured[name] = config
end
vim.lsp.enable = function(name)
  table.insert(enabled, name)
end

local function snapshot_registry()
  return vim.deepcopy(registry.entries)
end

local function restore_registry(snapshot)
  registry.entries = snapshot
end

local function new_state(tools)
  return { tools = tools, lsps = {}, formatters = {} }
end

local opts = { auto_lsp = true, auto_format = false }

-- astro lsp config loads from the lspconfig submodule
local state = new_state({
  ["npm:@astrojs/language-server"] = { { version = "2.0.0" } },
})
lsp.refresh(state, opts)
h.assert_not_nil(configured["astro"], "astro config should be loaded")
h.assert_not_nil(require("lspconfig.util"), "lspconfig.util should be requireable after refresh")
h.assert_eq(1, #state.lsps, "state.lsps tracks enabled LSPs")

-- A single tool can map to multiple LSP servers
configured = {}
enabled = {}
local snapshot = snapshot_registry()
registry.merge({
  ["npm:vscode-langservers-extracted"] = {
    lsp = { "html", "cssls", "jsonls" },
  },
})
state = new_state({ ["npm:vscode-langservers-extracted"] = { { version = "4.0.0" } } })
lsp.refresh(state, opts)
h.assert_not_nil(configured["html"], "html config loaded from lsp list")
h.assert_not_nil(configured["cssls"], "cssls config loaded from lsp list")
h.assert_not_nil(configured["jsonls"], "jsonls config loaded from lsp list")
h.assert_eq(3, #enabled, "all three LSPs from list are enabled")
restore_registry(snapshot)

-- Registry entry config is deep-merged over the bundled lspconfig
configured = {}
enabled = {}
snapshot = snapshot_registry()
registry.merge({
  ["lua-language-server"] = {
    config = {
      settings = { Lua = { workspace = { library = { "/some/path" } } } },
    },
  },
})
state = new_state({ ["lua-language-server"] = { { version = "3.18.0" } } })
lsp.refresh(state, opts)
h.assert_not_nil(configured["lua_ls"], "lua_ls config loaded")
h.assert_eq(
  "/some/path",
  configured["lua_ls"].settings.Lua.workspace.library[1],
  "registry config merged into lsp config"
)
h.assert_not_nil(configured["lua_ls"].on_init, "lua_ls inherits on_init from registry default")
restore_registry(snapshot)

-- Per-LSP overrides for multi-LSP entries
configured = {}
enabled = {}
snapshot = snapshot_registry()
registry.merge({
  ["npm:vscode-langservers-extracted"] = {
    lsp = { "html", "cssls", "jsonls" },
    config = {
      cssls = { settings = { css = { validate = false } } },
    },
  },
})
state = new_state({ ["npm:vscode-langservers-extracted"] = { { version = "4.0.0" } } })
lsp.refresh(state, opts)
h.assert_eq(
  false,
  configured["cssls"].settings.css.validate,
  "per-LSP override applies only to the named server"
)
h.assert_eq(
  nil,
  configured["html"].settings and configured["html"].settings.css,
  "non-overridden server does not receive another server's settings"
)
restore_registry(snapshot)

-- auto_lsp = false skips everything
configured = {}
enabled = {}
state = new_state({ ["npm:@astrojs/language-server"] = { { version = "2.0.0" } } })
lsp.refresh(state, { auto_lsp = false, auto_format = false })
h.assert_nil(configured["astro"], "auto_lsp=false skips configuration")
h.assert_eq(0, #state.lsps, "state.lsps empty when auto_lsp=false")

h.report("lsp")
