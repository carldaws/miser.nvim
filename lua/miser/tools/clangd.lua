return {
	requires = { "ninja" },
	filetypes = { "c", "cpp" },
	commands = {
		verify = "mise which clangd",
		install = "mise use clangd",
	}
}
