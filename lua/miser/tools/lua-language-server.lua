return {
	requires = { "lua" },
	filetypes = { "lua" },
	commands = {
		install = "mise use lua-language-server",
		verify = "mise which lua-language-server"
	}
}
