local miser = require("miser")
local status = require("miser.status")
local h = require("test.helpers")

local cwd = vim.fn.getcwd()
local home_cwd = vim.fn.fnamemodify(cwd, ":~")

local function new_state(tasks)
  return {
    tools = {},
    lsps = {},
    formatters = {},
    conflicts = {},
    tasks = tasks,
  }
end

local function task_lines(state, task_keymaps)
  miser.opts = { task_keymaps = task_keymaps }
  status.show(state)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.cmd("bwipeout!")
  local result = {}
  local in_tasks = false
  for _, line in ipairs(lines) do
    if line == "Tasks" then
      in_tasks = true
    elseif in_tasks and vim.startswith(line, "  ") then
      table.insert(result, vim.trim(line))
    elseif in_tasks and line == "" then
      break
    end
  end
  return result
end

local keymaps = { enabled = true, prefix = "<leader>m" }

-- Tasks without aliases are listed, project-local before global, then alphabetical
local lines = task_lines(new_state({
  { name = "global", aliases = {}, description = "", source = "/elsewhere/config.toml" },
  { name = "docx", aliases = {}, description = "", source = cwd .. "/.mise/tasks/docx" },
  { name = "clean", aliases = {}, description = "", source = cwd .. "/.mise/tasks/clean" },
}), keymaps)

h.assert_eq(3, #lines, "every task is listed")
h.assert_eq("clean  " .. home_cwd .. "/.mise/tasks/clean", lines[1], "local tasks sorted by name")
h.assert_eq("docx  " .. home_cwd .. "/.mise/tasks/docx", lines[2], "local tasks sorted by name")
h.assert_eq("global  /elsewhere/config.toml", lines[3], "global task listed last")

-- Description replaces the name, and the full keybind sits between label and source
lines = task_lines(new_state({
  { name = "dev", aliases = { "d" }, description = "Start dev", source = cwd .. "/mise.toml" },
}), keymaps)

h.assert_eq("Start dev  <leader>md  " .. home_cwd .. "/mise.toml", lines[1], "description, keybind, source")

-- Keybinds are omitted when task keymaps are disabled
lines = task_lines(new_state({
  { name = "dev", aliases = { "d" }, description = "", source = cwd .. "/mise.toml" },
}), { enabled = false, prefix = "<leader>m" })

h.assert_eq("dev  " .. home_cwd .. "/mise.toml", lines[1], "no keybind when keymaps disabled")

-- Empty task list shows the placeholder
lines = task_lines(new_state({}), keymaps)
h.assert_eq("(none)", lines[1], "placeholder when no tasks")

h.report("status")
