local miser = require("miser")
local command = require("miser.command")
local h = require("test.helpers")

miser.state = { tasks = { { name = "clean" }, { name = "docx" }, { name = "dev" } } }
command.setup()

local function complete(input)
  return table.concat(vim.fn.getcompletion(input, "cmdline"), ",")
end

-- Subcommands complete and filter on the typed prefix
h.assert_eq("format,install,run,status,trust", complete("Miser "), "all subcommands")
h.assert_eq("status", complete("Miser s"), "subcommands filtered by prefix")

-- Task names complete after run and filter on the typed prefix
h.assert_eq("clean,docx,dev", complete("Miser run "), "all task names after run")
h.assert_eq("docx,dev", complete("Miser run d"), "task names filtered by prefix")

-- Nothing completes past the task name or after other subcommands
h.assert_eq("", complete("Miser run clean "), "no completion for task args")
h.assert_eq("", complete("Miser status "), "no completion after status")

h.report("command")
