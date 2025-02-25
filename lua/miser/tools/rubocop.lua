return {
	requires = { "ruby" },
	filetypes = { "ruby" },
	commands = {
		install = "gem install rubocop",
		verify = "mise which rubocop"
	}
}
