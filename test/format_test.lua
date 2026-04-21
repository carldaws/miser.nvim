local format = require("miser.format")

local failures = 0

local function assert_eq(expected, actual, msg)
  if expected ~= actual then
    failures = failures + 1
    print("FAIL: " .. msg .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
  end
end

local function assert_nil(actual, msg)
  if actual ~= nil then
    failures = failures + 1
    print("FAIL: " .. msg .. " (expected nil, got " .. tostring(actual) .. ")")
  end
end

local function assert_not_nil(actual, msg)
  if actual == nil then
    failures = failures + 1
    print("FAIL: " .. msg .. " (expected non-nil)")
  end
end

-- Simulate tools that mise would return
local tools = {
  ["biome"] = { { version = "1.9.4" } },
  ["ruby"] = { { version = "3.3.10" } },
}

local formatters = format.setup(tools)

-- biome claims JS/TS filetypes
assert_not_nil(formatters["javascript"], "biome claims javascript")
assert_not_nil(formatters["typescript"], "biome claims typescript")
assert_not_nil(formatters["json"], "biome claims json")

-- biome cmd is correct
assert_eq("biome", formatters["javascript"][1], "biome cmd name")
assert_eq("format", formatters["javascript"][2], "biome cmd arg1")
assert_eq("--write", formatters["javascript"][3], "biome cmd arg2")

-- ruby is a runtime, not in registry — no formatters
assert_nil(formatters["ruby"], "ruby runtime has no formatter")

-- First tool wins: if both biome and prettier are declared, biome claims JS first
format._formatters = {}
local tools_both = {
  ["biome"] = { { version = "1.9.4" } },
  ["prettier"] = { { version = "3.0.0" } },
}
formatters = format.setup(tools_both)

-- Both claim javascript — one wins, the other doesn't
assert_not_nil(formatters["javascript"], "javascript is claimed")

-- Prettier claims filetypes biome doesn't
assert_not_nil(formatters["html"], "prettier claims html")
assert_not_nil(formatters["yaml"], "prettier claims yaml")

if failures == 0 then
  print("OK: all format tests passed")
else
  print(failures .. " test(s) failed")
  vim.cmd("cquit 1")
end
