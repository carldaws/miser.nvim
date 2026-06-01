local registry = require("miser.registry")

local M = {}

local function override_for(entry, lsp_name)
  if not entry.config then
    return nil
  end
  if type(entry.lsp) == "string" then
    return entry.config
  end
  return entry.config[lsp_name]
end

local function ensure_lspconfig()
  local miser_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  local lspconfig_root = miser_root .. "/deps/nvim-lspconfig"
  local lsp_dir = lspconfig_root .. "/lsp"
  if vim.fn.isdirectory(lsp_dir) == 0 then
    vim.fn.system({ "git", "-C", miser_root, "submodule", "update", "--init" })
    if vim.fn.isdirectory(lsp_dir) == 0 then
      return nil
    end
  end
  vim.opt.rtp:append(lspconfig_root)
  return lsp_dir
end

function M.refresh(state, opts)
  state.lsps = {}

  if not opts.auto_lsp then
    return
  end

  local lsp_dir = ensure_lspconfig()
  if not lsp_dir then
    vim.notify("miser: failed to init lspconfig submodule", vim.log.levels.WARN)
    return
  end

  for tool_name in pairs(state.tools) do
    local entry = registry.get(tool_name)
    if entry and entry.lsp then
      local lsp_names = type(entry.lsp) == "table" and entry.lsp or { entry.lsp }
      for _, lsp_name in ipairs(lsp_names) do
        local config_file = lsp_dir .. "/" .. lsp_name .. ".lua"
        if vim.fn.filereadable(config_file) == 1 then
          local config = dofile(config_file)
          local override = override_for(entry, lsp_name)
          if override then
            config = vim.tbl_deep_extend("force", config, override)
          end
          vim.lsp.config(lsp_name, config)
          vim.lsp.enable(lsp_name)
          table.insert(state.lsps, lsp_name)
        end
      end
    end
  end
end

function M.setup_format_on_save(state, opts)
  local group = vim.api.nvim_create_augroup("miser-lsp-format", { clear = true })

  if not (opts.auto_lsp and opts.auto_format) then
    return
  end

  local function bind(buf, client)
    if not vim.tbl_contains(state.lsps, client.name) then
      return
    end
    if state.formatters[vim.bo[buf].filetype] then
      return
    end
    if client:supports_method("textDocument/willSaveWaitUntil") then
      return
    end
    if not client:supports_method("textDocument/formatting") then
      return
    end
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      buffer = buf,
      callback = function()
        vim.lsp.buf.format({ bufnr = buf, name = client.name, timeout_ms = 1000 })
      end,
    })
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client then
        bind(ev.buf, client)
      end
    end,
  })

  for _, client in ipairs(vim.lsp.get_clients()) do
    for buf in pairs(client.attached_buffers or {}) do
      bind(buf, client)
    end
  end
end

return M
