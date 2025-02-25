return {
	requires = { "rust" },
	filetypes = { "rust" },
	commands = {
		install = "rustup component add rust-analyzer",
		verify = "mise which rust-analyzer"
	}
}
