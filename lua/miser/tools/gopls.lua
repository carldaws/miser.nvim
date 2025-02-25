return {
	requires = { "go" },
	filetypes = { "go" },
	commands = {
		install = "go install golang.org/x/tools/gopls@latest",
		verify = "mise which gopls"
	}
}
