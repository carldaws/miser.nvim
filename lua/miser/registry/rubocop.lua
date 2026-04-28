return {
  ["gem:rubocop"] = {
    lsp = "rubocop",
    formatter = {
      filetypes = { "ruby" },
      cmd = { "rubocop", "-A", "--stderr" },
    },
  },
}
