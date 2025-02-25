return {
	requires = { "node" },
	filetypes = { "javascript", "typescript" },
	commands = {
		install = "npm install -g typescript-language-server",
		verify = "mise which typescript-language-server"
	}
}
