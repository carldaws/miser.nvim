return {
  ["biome"] = {
    formatter = {
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "css" },
      cmd = { "biome", "format", "--write" },
    },
  },
}
