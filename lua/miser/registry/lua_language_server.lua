return {
  ["lua-language-server"] = {
    lsp = "lua_ls",
    config = {
      on_init = function(client)
        if client.workspace_folders then
          local root = client.workspace_folders[1].name
          if vim.uv.fs_stat(root .. "/.luarc.json") or vim.uv.fs_stat(root .. "/.luarc.jsonc") then
            return
          end
        end
        client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
          runtime = {
            version = "LuaJIT",
            path = { "lua/?.lua", "lua/?/init.lua" },
          },
          workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
          },
        })
      end,
      settings = { Lua = {} },
    },
  },
}
