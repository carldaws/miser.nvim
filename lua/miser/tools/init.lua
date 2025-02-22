local M = {}

local tool_files = {
	"miser.tools.node",
	"miser.tools.ruby",
	"miser.tools.lua",
	"miser.tools.go",
	"miser.tools.rust",
}

for _, file in ipairs(tool_files) do
	local env_tools = require(file)
	for env, tools in pairs(env_tools) do
		if not M[env] then
			M[env] = {}
		end
		for tool, config in pairs(tools) do
			M[env][tool] = config
			M[tool] = config
			M[tool].requires = env
		end
	end
end

return M
