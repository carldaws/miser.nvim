return {
  ["ruff"] = {
    lsp = "ruff",
    formatter = {
      filetypes = { "python" },
      cmd = { "ruff", "format" },
    },
  },
}
