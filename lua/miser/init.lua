local M = {}

M.filetypes = {}

M.install_filetype_tools = function(filetype)
	local ft_data = M.filetypes[filetype]
	if not ft_data then
		return
	end

	for tool_name, tool in pairs(ft_data.tools) do
		for _, requirement in ipairs(tool.requires) do
			local module_loaded, requirement_data = pcall(require, "miser.tools." .. requirement)
			if module_loaded then
				local success = os.execute(requirement_data.commands.verify)
				if success ~= 0 then
					local choice = vim.fn.input(requirement .. " not installed, install it? (Y/n): ")
					if choice:lower() == "y" or choice == "" then
						vim.notify("Installing " .. requirement .. "...", vim.log.levels.INFO)
						os.execute(requirement_data.commands.install)
						vim.notify(requirement .. " installed!")
					else
						vim.notify("Installation skipped", vim.log.levels.INFO)
						return
					end
				end
			end
		end

		local success = os.execute(tool.commands.verify)
		if success ~= 0 then
			local choice = vim.fn.input(tool_name .. " not installed, install it? (Y/n): ")
			if choice:lower() == "y" or choice == "" then
				vim.notify("Installing " .. tool_name .. "...", vim.log.levels.INFO)
				os.execute(tool.commands.install)
				vim.notify(tool_name .. " installed!")
			else
				vim.notify("Installation skipped", vim.log.levels.INFO)
				return
			end
		end
	end
end

M.setup = function(opts)
	M.config = opts or {}

	if vim.fn.executable("mise") == 0 then
		vim.notify("Miser: Mise not found, is it installed?", vim.log.levels.ERROR)
		return
	end

	for _, tool in ipairs(M.config.tools or {}) do
		local module_loaded, tool_data = pcall(require, "miser.tools." .. tool)
		if not module_loaded then
			vim.notify("Miser: Unknown tool " .. tool, vim.log.levels.ERROR)
		else
			for _, filetype in ipairs(tool_data.filetypes) do
				M.filetypes[filetype] = M.filetypes[filetype] or { tools = {} }
				M.filetypes[filetype].tools[tool] = {
					requires = tool_data.requires,
					commands = tool_data.commands
				}
			end
		end
	end

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("MiserFileType", { clear = true }),
		callback = function(event)
			M.install_filetype_tools(event.match)
		end
	})
end

return M
