return {
	requires = { "node" },
	filetypes = { "javascript", "typescript" },
	commands = {
		install = "npm install -g prettier",
		verify = "mise which prettier"
	}
}
