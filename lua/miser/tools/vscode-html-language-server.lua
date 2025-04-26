return {
	requires = { "node" },
	filetypes = { "html", "css" },
	commands = {
		install = "npm install -g vscode-langservers-extracted",
		verify = "mise which vscode-html-language-server"
	}
}
