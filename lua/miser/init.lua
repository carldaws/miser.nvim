local M = {}

M.filetypes = {}
M.installed = {}

M.run = function(command, on_success, on_failure)
	local _ = vim.fn.system(command)
	if vim.v.shell_error == 0 then
		on_success()
	else
		on_failure()
	end
end

M.verify_or_install = function(tool, tool_data)
	if M.installed[tool] then
		return
	end

	M.run(
		tool_data.commands.verify,
		function()
			M.installed[tool] = true
		end,
		function()
			local choice = vim.fn.input("Miser: " .. tool .. " not installed, install it? (Y/n): ")
			if choice:lower() == "y" or choice == "" then
				M.run(
					tool_data.commands.install,
					function()
						vim.notify("Miser: " .. tool .. " installed!", vim.log.levels.INFO)
						M.installed[tool] = true
					end,
					function()
						vim.notify("Miser: Error installing " .. tool, vim.log.levels.ERROR)
					end
				)
			else
				vim.notify("Miser: Installation of " .. tool .. " skipped", vim.log.levels.INFO)
			end
		end
	)
end

M.install_filetype_tools = function(filetype)
	local ft_data = M.filetypes[filetype]
	if not ft_data then
		return
	end

	for tool, tool_data in pairs(ft_data.tools) do
		for _, requirement in ipairs(tool_data.requires) do
			local module_loaded, requirement_data = pcall(require, "miser.tools." .. requirement)
			if module_loaded then
				M.verify_or_install(requirement, requirement_data)
			else
				vim.notify("Miser: No such requirement " .. requirement .. " found", vim.log.levels.ERROR)
			end
		end

		M.verify_or_install(tool, tool_data)
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
