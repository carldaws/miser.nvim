local format = require("miser.format")
local h = require("test.helpers")

local function new_state(tools)
  return {
    tools = tools,
    formatters = {},
    conflicts = {},
  }
end

local opts = { auto_format = false }

-- Biome claims JS/TS/JSON/CSS filetypes
local state = new_state({
  ["biome"] = { { version = "1.9.4" } },
  ["ruby"] = { { version = "3.3.10" } },
})
format.refresh(state, opts)

h.assert_not_nil(state.formatters["javascript"], "biome claims javascript")
h.assert_not_nil(state.formatters["typescript"], "biome claims typescript")
h.assert_not_nil(state.formatters["json"], "biome claims json")
h.assert_eq("biome", state.formatters["javascript"][1], "biome cmd name")
h.assert_eq("format", state.formatters["javascript"][2], "biome cmd arg1")
h.assert_eq("--write", state.formatters["javascript"][3], "biome cmd arg2")
h.assert_nil(state.formatters["ruby"], "ruby runtime has no formatter")
h.assert_eq(0, #state.conflicts, "no conflicts with single claim")

-- Two formatters for the same filetype: skip + record conflict
state = new_state({
  ["biome"] = { { version = "1.9.4" } },
  ["prettier"] = { { version = "3.0.0" } },
})
format.refresh(state, opts)

h.assert_nil(state.formatters["javascript"], "javascript not claimed when two formatters compete")
h.assert_nil(state.formatters["typescript"], "typescript not claimed when two formatters compete")
h.assert_not_nil(state.formatters["html"], "prettier-only filetypes still claimed")
h.assert_not_nil(state.formatters["yaml"], "prettier-only filetypes still claimed")

local js_conflict
for _, c in ipairs(state.conflicts) do
  if c.filetype == "javascript" then
    js_conflict = c
  end
end
h.assert_not_nil(js_conflict, "conflict recorded for javascript")
if js_conflict then
  h.assert_eq("biome", js_conflict.tools[1], "conflict tools sorted alphabetically")
  h.assert_eq("prettier", js_conflict.tools[2], "conflict tools sorted alphabetically")
end

-- Rubocop claims ruby
state = new_state({ ["gem:rubocop"] = {} })
format.refresh(state, opts)
h.assert_not_nil(state.formatters["ruby"], "rubocop claims ruby")
h.assert_eq("rubocop", state.formatters["ruby"][1], "rubocop cmd name")
h.assert_eq("-A", state.formatters["ruby"][2], "rubocop cmd arg1")
h.assert_eq("--stderr", state.formatters["ruby"][3], "rubocop cmd arg2")

h.report("format")
