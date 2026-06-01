local M = {}

function M.show(state)
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

  local function empty()
    table.insert(lines, "  (none)")
    hl("Comment", #lines - 1, 2)
  end

  -- Tools: project-local first, then global, then alphabetical
  heading("Tools")
  local cwd = vim.fn.getcwd()
  local sorted_tools = {}
  for tool_name, versions in pairs(state.tools) do
    local v = versions[1]
    local source_path = v and v.source and v.source.path or ""
    table.insert(sorted_tools, {
      name = tool_name,
      version = v and v.version or "?",
      source = vim.fn.fnamemodify(source_path, ":~"),
      is_local = vim.startswith(source_path, cwd),
    })
  end
  table.sort(sorted_tools, function(a, b)
    if a.is_local ~= b.is_local then
      return a.is_local
    end
    return a.name < b.name
  end)
  if #sorted_tools == 0 then
    empty()
  else
    for _, tool in ipairs(sorted_tools) do
      local line = "  " .. tool.name .. " " .. tool.version
      local source_col = #line + 2
      line = line .. "  " .. tool.source
      table.insert(lines, line)
      hl("@variable", #lines - 1, 2, 2 + #tool.name)
      hl("Number", #lines - 1, 3 + #tool.name, 3 + #tool.name + #tool.version)
      hl("Comment", #lines - 1, source_col, #line)
    end
  end
  gap()

  -- LSP servers
  heading("LSP Servers")
  if #state.lsps > 0 then
    for _, name in ipairs(state.lsps) do
      local clients = vim.lsp.get_clients({ name = name })
      local running = #clients > 0
      local indicator = running and "● " or "○ "
      local label = running and "running" or "ready"
      local line = "  " .. indicator .. name .. "  " .. label
      table.insert(lines, line)
      hl(running and "DiagnosticOk" or "Comment", #lines - 1, 2, 2 + #indicator)
      hl("@variable", #lines - 1, 2 + #indicator, 2 + #indicator + #name)
      hl("Comment", #lines - 1, #line - #label, #line)
    end
  else
    empty()
  end
  gap()

  -- Formatters: group by command
  heading("Formatters")
  if not vim.tbl_isempty(state.formatters) then
    local by_cmd = {}
    for ft, cmd in pairs(state.formatters) do
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
    empty()
  end

  gap()

  -- Tasks: only those with aliases (the ones with keymaps), project-local first
  heading("Tasks")
  local aliased = {}
  for _, task in ipairs(state.tasks) do
    if task.aliases and #task.aliases > 0 then
      local source_path = task.source or ""
      local description = task.description ~= "" and task.description or nil
      table.insert(aliased, {
        name = task.name,
        label = description or task.name,
        aliases = task.aliases,
        source = vim.fn.fnamemodify(source_path, ":~"),
        is_local = vim.startswith(source_path, cwd),
      })
    end
  end
  if #aliased > 0 then
    table.sort(aliased, function(a, b)
      if a.is_local ~= b.is_local then
        return a.is_local
      end
      return a.name < b.name
    end)
    for _, task in ipairs(aliased) do
      local aliases = table.concat(task.aliases, ", ")
      local line = "  " .. task.label .. "  " .. aliases .. "  " .. task.source
      table.insert(lines, line)
      hl("@variable", #lines - 1, 2, 2 + #task.label)
      hl("Comment", #lines - 1, 2 + #task.label, #line)
    end
  else
    empty()
  end

  -- Conflicts: only if any
  if #state.conflicts > 0 then
    gap()
    heading("Conflicts")
    for _, c in ipairs(state.conflicts) do
      local line = "  " .. c.filetype .. "  " .. table.concat(c.tools, ", ")
      table.insert(lines, line)
      hl("DiagnosticWarn", #lines - 1, 2, 2 + #c.filetype)
      hl("Comment", #lines - 1, 2 + #c.filetype, #line)
    end
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
    require("miser").install()
  end, { buffer = buf, nowait = true, desc = "mise install + refresh" })
end

return M
