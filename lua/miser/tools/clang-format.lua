return {
	requires = { "ninja" },
	filetypes = { "c", "cpp" },
	commands = {
		verify = "mise which clang-format",
		install = "mise use clang-format",
	}
}
