local M = {}

local tools = require("miser.tools")

M.config = {
	tools = {},
	auto_install = true,
	ensure_installed = {}
}

M.search = function(tool)
	vim.notify("Search not implemented yet, you searched for " .. tool, vim.log.levels.INFO)
end

M.install = function(_tool, _callback)
	local tool = tools[_tool]
	local default_callback = function(_, exit_code, _)
		if exit_code == 0 then
			vim.notify("Miser: " .. _tool .. " successfully installed", vim.log.levels.INFO)
		else
			vim.notify("Miser: " .. _tool .. " failed to install", vim.log.levels.ERROR)
		end
	end

	local callback = _callback or default_callback

	if tool == nil then
		vim.notify("Miser: Requested tool " .. _tool .. " not supported", vim.log.levels.ERROR)
		return
	end

	if vim.fn.executable("mise") == 0 then
		vim.notify("Miser: Mise not found, is it installed?", vim.log.levels.ERROR)
		return
	end

	if vim.fn.executable(tool.requires) == 0 then
		vim.notify("Miser: No " .. tool.requires .. " found, try 'mise use " .. tool.requires .. "'",
			vim.log.levels.ERROR)
		return
	end

	local mise_path = vim.trim(vim.fn.system("mise which " .. _tool))
	if mise_path == "" or mise_path:match("not a mise bin") then
		vim.notify("Miser: Installing " .. _tool, vim.log.levels.INFO)
		vim.fn.jobstart(tool.install, { on_exit = callback })
	else
		vim.notify("Miser: " .. _tool .. " installed", vim.log.levels.INFO)
	end
end

M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	if M.config.auto_install then
		local original_start_client = vim.lsp.start_client

		vim.lsp.start_client = function(config)
			local executable = config.cmd[1]:match("([^/]+)$")

			M.install(executable, function(_, exit_code, _)
				local bufnr = vim.api.nvim_get_current_buf()
				if exit_code == 0 then
					vim.notify("Miser: " .. executable .. " installed successfully", vim.log.levels.INFO)
					local client = original_start_client(config)

					if client then
						vim.notify("Miser: Attaching " .. executable .. " to buffer " .. bufnr, vim.log.levels.INFO)
						vim.lsp.buf_attach_client(bufnr, client)
					end
					return
				else
					vim.notify("Miser: " .. executable .. " failed to install", vim.log.levels.ERROR)
				end
			end)

			return original_start_client(config)
		end
	end

	for _, tool in ipairs(M.config.ensure_installed) do
		M.install(tool)
	end
end

vim.api.nvim_create_user_command("MiserInstall", function(opts)
	M.install(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("MiserSearch", function(opts)
	M.search(opts.args)
end, { nargs = 1 })

return M
