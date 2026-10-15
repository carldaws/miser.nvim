return {
  ["prettier"] = {
    formatter = {
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "css", "html", "json", "yaml", "markdown", "astro", "svelte" },
      cmd = { "prettier", "--write" },
    },
  },
}
