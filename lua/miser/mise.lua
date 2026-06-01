local M = {}

local function json(args)
  local result = vim.system(vim.list_extend({ "mise" }, args), { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  local ok, data = pcall(vim.json.decode, result.stdout)
  return ok and data or nil
end

function M.available()
  return vim.fn.executable("mise") == 1
end

function M.version()
  local result = vim.system({ "mise", "--version" }, { text = true }):wait()
  if result.code ~= 0 then
    return "?"
  end
  return vim.trim(result.stdout)
end

function M.tools()
  return json({ "ls", "--current", "--json" }) or {}
end

function M.tasks()
  return json({ "task", "ls", "--json" }) or {}
end

function M.configs()
  return json({ "config", "ls", "--json" }) or {}
end

function M.bin_paths()
  local result = vim.system({ "mise", "bin-paths" }, { text = true }):wait()
  if result.code ~= 0 then
    return {}
  end
  return vim.split(result.stdout, "\n", { trimempty = true })
end

local function async(args, label, on_done)
  vim.system(vim.list_extend({ "mise" }, args), { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("miser: " .. label .. " failed\n" .. (result.stderr or ""), vim.log.levels.ERROR)
      end
      if on_done then
        on_done(result.code == 0)
      end
    end)
  end)
end

function M.install(on_done)
  async({ "install" }, "mise install", on_done)
end

function M.trust(on_done)
  async({ "trust" }, "mise trust", on_done)
end

function M.task_cmd(name, args)
  local cmd = { "mise", "run", name }
  if args and #args > 0 then
    table.insert(cmd, "--")
    vim.list_extend(cmd, args)
  end
  return cmd
end

return M
