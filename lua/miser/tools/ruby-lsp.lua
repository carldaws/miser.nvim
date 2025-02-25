return {
	requires = { "ruby" },
	filetypes = { "ruby" },
	commands = {
		install = "gem install ruby-lsp",
		verify = "mise which ruby-lsp"
	}
}
