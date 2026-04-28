local M = {}

local function register(entries)
  for tool, config in pairs(entries) do
    M.entries[tool] = config
  end
end

M.entries = {}

register(require("miser.registry.astro"))
register(require("miser.registry.biome"))
register(require("miser.registry.black"))
register(require("miser.registry.gofumpt"))
register(require("miser.registry.gopls"))
register(require("miser.registry.lua_language_server"))
register(require("miser.registry.prettier"))
register(require("miser.registry.rubocop"))
register(require("miser.registry.ruby_lsp"))
register(require("miser.registry.ruff"))
register(require("miser.registry.shfmt"))
register(require("miser.registry.stylua"))
register(require("miser.registry.typescript_language_server"))

function M.get(tool_name)
  return M.entries[tool_name]
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
