return {
	requires = { "node" },
	filetypes = { "javascript", "typescript" },
	commands = {
		install = "npm install -g eslint",
		verify = "mise which eslint"
	}
}
