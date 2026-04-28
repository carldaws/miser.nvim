local lsp = require("miser.lsp")

local failures = 0

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

if failures == 0 then
  print("OK: all lsp tests passed")
else
  print(failures .. " test(s) failed")
  vim.cmd("cquit 1")
end
