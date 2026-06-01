local M = {}

M.failures = 0

function M.assert_eq(expected, actual, msg)
  if expected ~= actual then
    M.failures = M.failures + 1
    print("FAIL: " .. msg .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
  end
end

function M.assert_nil(actual, msg)
  if actual ~= nil then
    M.failures = M.failures + 1
    print("FAIL: " .. msg .. " (expected nil, got " .. tostring(actual) .. ")")
  end
end

function M.assert_not_nil(actual, msg)
  if actual == nil then
    M.failures = M.failures + 1
    print("FAIL: " .. msg .. " (expected non-nil)")
  end
end

function M.report(name)
  if M.failures == 0 then
    print("OK: all " .. name .. " tests passed")
  else
    print(M.failures .. " " .. name .. " test(s) failed")
    vim.cmd("cquit 1")
  end
end

return M
