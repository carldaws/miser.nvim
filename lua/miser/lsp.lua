local registry = require("miser.registry")

local M = {}

function M.setup(tools)
  local miser_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  local lsp_dir = miser_root .. "/deps/nvim-lspconfig/lsp"

  local enabled = {}

  for tool_name, _ in pairs(tools) do
    local entry = registry.get(tool_name)
    if entry and entry.lsp then
      local config_file = lsp_dir .. "/" .. entry.lsp .. ".lua"
      if vim.fn.filereadable(config_file) == 1 then
        vim.lsp.config(entry.lsp, dofile(config_file))
        vim.lsp.enable(entry.lsp)
        table.insert(enabled, entry.lsp)
      end
    end
  end

  return enabled
end

function M.setup_format_on_save()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("miser-lsp-format", { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client then
        return
      end
      if not client:supports_method("textDocument/willSaveWaitUntil")
          and client:supports_method("textDocument/formatting")
      then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = ev.buf,
          callback = function()
            vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 1000 })
          end,
        })
      end
    end,
  })
end

return M
