return {
	requires = { "rust" },
	filetypes = { "toml" },
	commands = {
		install = "cargo install --features lsp --locked taplo-cli",
		verify = "mise which taplo",
	}
}
