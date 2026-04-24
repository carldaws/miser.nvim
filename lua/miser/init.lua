local M = {}

M.defaults = {
  auto_install = true,
  auto_format = true,
  auto_lsp = true,
  registry = {},
  task_runner = nil,
}

M._state = {
  tools = {},
  enabled_lsps = {},
  formatters = {},
}

M._path_activated = false

function M.activate(opts)
  if not M._path_activated then
    local bin_paths = vim.fn.systemlist({ "mise", "bin-paths" })
    if #bin_paths > 0 then
      vim.env.PATH = table.concat(bin_paths, ":") .. ":" .. vim.env.PATH
    end
    M._path_activated = true
  end

  local json = vim.fn.system({ "mise", "ls", "--current", "--json" })
  local ok, tools = pcall(vim.json.decode, json)
  if not ok or not tools then
    tools = {}
  end

  M._state.tools = tools

  if opts.auto_lsp then
    M._state.enabled_lsps = require("miser.lsp").setup(tools)
  end
  if opts.auto_format then
    M._state.formatters = require("miser.format").setup(tools)
  end
end

function M.show_status()
  local lines = {}
  local highlights = {}
  local ns = vim.api.nvim_create_namespace("miser-status")

  local function hl(group, line, col_start, col_end)
    table.insert(highlights, { group, line, col_start, col_end, col_end == nil })
  end

  local function heading(text)
    table.insert(lines, text)
    hl("@markup.heading", #lines - 1, 0, #text)
    table.insert(lines, string.rep("─", #text))
    hl("FloatBorder", #lines - 1, 0)
  end

  local function gap()
    table.insert(lines, "")
  end

  -- Tools: sort by source depth (project-local first, global last)
  heading("Tools")
  local cwd = vim.fn.getcwd()
  local sorted_tools = {}
  for tool_name, versions in pairs(M._state.tools) do
    local v = versions[1]
    local source_path = v and v.source and v.source.path or ""
    local is_local = vim.startswith(source_path, cwd)
    table.insert(sorted_tools, {
      name = tool_name,
      version = v and v.version or "?",
      source = vim.fn.fnamemodify(source_path, ":~"),
      is_local = is_local,
    })
  end
  table.sort(sorted_tools, function(a, b)
    if a.is_local ~= b.is_local then
      return a.is_local
    end
    return a.name < b.name
  end)
  for _, tool in ipairs(sorted_tools) do
    local line = "  " .. tool.name .. " " .. tool.version
    local source_col = #line + 2
    line = line .. "  " .. tool.source
    table.insert(lines, line)
    hl("@variable", #lines - 1, 2, 2 + #tool.name)
    hl("Number", #lines - 1, 3 + #tool.name, 3 + #tool.name + #tool.version)
    hl("Comment", #lines - 1, source_col, #line)
  end
  gap()

  -- LSP servers with running/enabled status
  heading("LSP Servers")
  if #M._state.enabled_lsps > 0 then
    for _, name in ipairs(M._state.enabled_lsps) do
      local clients = vim.lsp.get_clients({ name = name })
      local running = #clients > 0
      local indicator = running and "● " or "○ "
      local indicator_bytes = #indicator
      local label = running and "running" or "ready"
      local line = "  " .. indicator .. name .. "  " .. label
      table.insert(lines, line)
      hl(running and "DiagnosticOk" or "Comment", #lines - 1, 2, 2 + indicator_bytes)
      hl("@variable", #lines - 1, 2 + indicator_bytes, 2 + indicator_bytes + #name)
      hl("Comment", #lines - 1, #line - #label, #line)
    end
  else
    table.insert(lines, "  (none)")
    hl("Comment", #lines - 1, 2)
  end
  gap()

  -- Formatters: group by command
  heading("Formatters")
  if not vim.tbl_isempty(M._state.formatters) then
    local by_cmd = {}
    for ft, cmd in pairs(M._state.formatters) do
      local key = table.concat(cmd, " ")
      if not by_cmd[key] then
        by_cmd[key] = { cmd = key, filetypes = {} }
      end
      table.insert(by_cmd[key].filetypes, ft)
    end
    for _, entry in pairs(by_cmd) do
      table.sort(entry.filetypes)
      local fts = table.concat(entry.filetypes, ", ")
      local line = "  " .. entry.cmd .. "  " .. fts
      table.insert(lines, line)
      hl("@variable", #lines - 1, 2, 2 + #entry.cmd)
      hl("Comment", #lines - 1, #line - #fts, #line)
    end
  else
    table.insert(lines, "  (none)")
    hl("Comment", #lines - 1, 2)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width + 4, math.floor(vim.o.columns * 0.8))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.6))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " miser ",
    title_pos = "center",
  })

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].cursorline = true

  for _, h in ipairs(highlights) do
    local ext_opts = { hl_group = h[1] }
    if h[5] then
      ext_opts.end_row = h[2] + 1
    else
      ext_opts.end_col = h[4]
    end
    vim.api.nvim_buf_set_extmark(buf, ns, h[2], h[3], ext_opts)
  end

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, nowait = true })
  vim.keymap.set("n", "i", function()
    vim.cmd("close")
    require("miser.install").run(function()
      M.activate(M._opts)
      M.show_status()
    end)
  end, { buffer = buf, nowait = true })
end

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})
  M._opts = opts

  if vim.fn.executable("mise") == 0 then
    vim.notify("miser: mise not found in PATH", vim.log.levels.ERROR)
    return
  end

  local registry = require("miser.registry")
  if not vim.tbl_isempty(opts.registry) then
    registry.merge(opts.registry)
  end

  if opts.task_runner then
    require("miser.tasks")._task_runner = opts.task_runner
  end

  M.activate(opts)

  if opts.auto_install then
    require("miser.install").run()
  end

  if opts.auto_lsp then
    require("miser.lsp").setup_format_on_save()
  end

  vim.api.nvim_create_user_command("Miser", function(cmd_opts)
    local args = cmd_opts.fargs
    local subcmd = args[1]

    if subcmd == "run" then
      local task_name = args[2]
      if not task_name then
        vim.notify("miser: usage: Miser run <task> [args...]", vim.log.levels.WARN)
        return
      end
      require("miser.tasks").run(task_name, vim.list_slice(args, 3))
    elseif subcmd == "trust" then
      require("miser.trust").run(function()
        M.activate(M._opts)
      end)
    elseif subcmd == "install" then
      require("miser.install").run(function()
        M.activate(M._opts)
      end)
    elseif subcmd == "status" then
      M.show_status()
    else
      vim.notify("miser: unknown command '" .. (subcmd or "") .. "'\nUsage: Miser status | run <task> | install | trust", vim.log.levels.WARN)
    end
  end, {
    nargs = "+",
    complete = function(_, line)
      local parts = vim.split(line, "%s+")
      if #parts <= 2 then
        return { "install", "run", "status", "trust" }
      end
      return {}
    end,
  })
end

return M
