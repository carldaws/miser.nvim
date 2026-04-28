return {
  ["shfmt"] = {
    formatter = {
      filetypes = { "sh", "bash", "zsh" },
      cmd = { "shfmt", "-w" },
    },
  },
}
