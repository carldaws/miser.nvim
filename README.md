# miser.nvim

**miser** bridges [mise](https://github.com/jdx/mise) and Neovim. Declare your tools in `mise.toml` and miser handles the rest: LSP servers start, formatters run on save, and mise tasks are a keypress away.

No more mason, no more global installs drifting out of sync, no more hardcoding formatters in your Neovim config. The project decides which tools it needs. Miser makes Neovim respect that.

## How it works

1. On startup, miser reads your project's mise tools via `mise ls --current`
2. Each tool is looked up in a **registry** that maps mise tool names to LSP server names and formatter commands
3. LSP configs are loaded from the bundled [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) and enabled via `vim.lsp.config` / `vim.lsp.enable`
4. Formatters run on save via `BufWritePost` — the project's `mise.toml` determines which formatter, not your Neovim config
5. `mise install` runs in the background to ensure tools are up to date

## Requirements

- Neovim >= 0.11
- [mise](https://mise.jdx.dev/) installed and on your PATH

## Installation

With `vim.pack.add` (Neovim 0.11+):

```lua
vim.pack.add({
  { src = "https://github.com/carldaws/miser.nvim" },
})
```

With lazy.nvim:

```lua
{
  "carldaws/miser.nvim",
  config = function()
    require("miser").setup()
  end,
}
```

Miser bundles nvim-lspconfig as a git submodule. If your plugin manager doesn't fetch submodules automatically, miser will init it on first run.

## Setup

```lua
require("miser").setup()
```

That's it. If your project has a `mise.toml` with tools declared, miser will configure LSPs and formatters automatically.

### Options

```lua
require("miser").setup({
  auto_install = true,   -- run `mise install` on startup (default: true)
  auto_format = true,    -- format on save via registry (default: true)
  auto_lsp = true,       -- auto-configure LSPs from mise tools (default: true)
  registry = {},         -- override or extend the built-in registry (see below)
  task_runner = nil,     -- callback receiving a command string (default: terminal split)
})
```

## Example

Given a project `mise.toml`:

```toml
[tools]
"npm:typescript-language-server" = "latest"
biome = "1.9.4"

[tasks.dev]
description = "Start the dev server"
run = "npm run dev"

[tasks.test]
description = "Run the test suite"
run = "npm test"
```

Miser will:
- Enable the `ts_ls` LSP for JavaScript and TypeScript files
- Format JS/TS/JSON/CSS files with `biome format --write` on save
- Run `mise install` in the background to ensure both tools are available
- Make `dev` and `test` available via `miser.tasks.list()` and `:Miser run`

No LSP config blocks. No formatter autocmds. Just declare your tools.

## Commands

| Command | Description |
|---------|-------------|
| `:Miser status` | Open a status panel showing tools, LSPs, and formatters |
| `:Miser install` | Run `mise install` and re-activate LSPs and formatters |
| `:Miser run <task>` | Run a mise task via your configured `task_runner` |

The status panel supports:
- `q` / `<Esc>` to close
- `i` to run `mise install` and refresh

## Health check

Run `:checkhealth miser` to verify your setup — checks for mise, the lspconfig submodule, project tools, and running LSP clients.

## Tasks

Miser exposes mise tasks via a simple API — wire it up to any picker:

```lua
-- With mini.pick
vim.keymap.set("n", "<leader>mt", function()
  require("miser.tasks").list(function(tasks)
    require("mini.pick").start({
      source = {
        name = "Mise Tasks",
        items = vim.tbl_map(function(t) return t.name end, tasks),
        choose = function(chosen)
          if chosen then require("miser.tasks").run(chosen) end
        end,
      },
    })
  end)
end)
```

```lua
-- With vim.ui.select
vim.keymap.set("n", "<leader>mt", function()
  require("miser.tasks").list(function(tasks)
    vim.ui.select(tasks, {
      prompt = "Mise Tasks:",
      format_item = function(t) return t.name end,
    }, function(choice)
      if choice then require("miser.tasks").run(choice.name) end
    end)
  end)
end)
```

### Pairing with surface.nvim

Miser tasks pair well with [surface.nvim](https://github.com/carldaws/surface.nvim) for persistent, toggleable terminal windows. Instead of throwaway splits, tasks open in surface windows that you can dismiss and resurface later — great for long-running tasks like dev servers:

```lua
require("miser").setup({
  task_runner = function(cmd)
    require("surface").open(cmd, "bottom")
  end,
})
```

Now both `:Miser run dev` and your picker keymap route through surface:

```lua
vim.keymap.set("n", "<leader>mt", function()
  require("miser.tasks").list(function(tasks)
    vim.ui.select(tasks, {
      prompt = "Mise Tasks:",
      format_item = function(t) return t.name end,
    }, function(choice)
      if choice then
        vim.schedule(function()
          require("miser.tasks").run(choice.name)
        end)
      end
    end)
  end)
end)
```

Pick "dev", the server starts in a surface window. Dismiss it, keep coding. Resurface it later with the same keymap — your server output is still there.

## The Registry

The registry maps mise tool names to LSP server names and formatter commands. Each tool has its own file under `lua/miser/registry/`, keyed by the exact tool name you'd write in `mise.toml`.

**LSP entries** are just name mappings — miser loads the full config from the bundled nvim-lspconfig:

```lua
["npm:typescript-language-server"] = { lsp = "ts_ls" },
["go:golang.org/x/tools/gopls"] = { lsp = "gopls" },
```

**Formatter entries** define the command and which filetypes it handles:

```lua
["biome"] = {
  formatter = {
    filetypes = { "javascript", "typescript", "json", "css" },
    cmd = { "biome", "format", "--write" },
  },
},
```

Tools can have both:

```lua
["gem:rubocop"] = {
  lsp = "rubocop",
  formatter = {
    filetypes = { "ruby" },
    cmd = { "rubocop", "-A", "--stderr" },
  },
},
```

### Built-in entries

| mise.toml tool | LSP | Formatter |
|----------------|-----|-----------|
| lua-language-server | lua_ls | |
| gem:ruby-lsp | ruby_lsp | |
| gem:rubocop | rubocop | rubocop -A |
| npm:typescript-language-server | ts_ls | |
| npm:@astrojs/language-server | astro | |
| go:golang.org/x/tools/gopls | gopls | |
| zls | zls | |
| ruff | ruff | ruff format |
| biome | | biome format --write |
| prettier | | prettier --write |
| stylua | | stylua |
| gofumpt | | gofumpt -w |
| black | | black |
| shfmt | | shfmt -w |

### Extending the registry

```lua
require("miser").setup({
  registry = {
    ["npm:my-lsp"] = { lsp = "my_ls" },
    ["my-formatter"] = {
      formatter = {
        filetypes = { "custom" },
        cmd = { "my-fmt", "--write" },
      },
    },
  },
})
```

## Coming from Mason

If you already have LSPs and formatters configured via mason.nvim and mason-lspconfig, you don't need to throw any of that away. Miser can replace Mason purely as a tool manager — just disable the automation:

```lua
require("miser").setup({
  auto_lsp = false,
  auto_format = false,
})
```

This puts mise's `bin-paths` on Neovim's PATH and runs `mise install`, but doesn't touch your LSP or formatter config. Your existing lspconfig setup, conform.nvim, or whatever else you use keeps working exactly as before — the only difference is that mise manages the binaries instead of Mason.

From there you can remove `mason.nvim` and `mason-lspconfig.nvim` from your plugin list and declare the same tools in `mise.toml` instead. The servers and formatters are the same binaries, just installed and versioned by mise.

You can also mix and match: leave `auto_lsp = true` for tools where the defaults work and handle the rest yourself. Or override specific registry entries to change formatter commands without replacing the whole setup.

## How I use mise and Neovim

Mise configs are layered — global, project, and local — and `mise ls --current` resolves them all for the current directory. Miser reads that resolved list, so you can structure your mise configs to fit different situations:

**Global `~/.config/mise/config.toml`** — baseline tools you want everywhere. Language servers, formatters, and runtimes that make up your default editing environment:

```toml
[tools]
lua-language-server = "latest"
stylua = "latest"
node = "22"
```

**Project `mise.toml`** — committed to the repo. The team's agreed-upon tools and tasks. Everyone gets the same versions:

```toml
[tools]
"npm:typescript-language-server" = "latest"
biome = "1.9.4"

[tasks.dev]
run = "npm run dev"
```

**Project `mise.local.toml`** — gitignored, personal overrides. I use this in two situations:

1. **Adding tools to projects that don't use mise.** I add `mise.local.toml` to my global gitignore (`~/.config/git/ignore`) so I can drop one into any project without it showing up in version control. The project doesn't need to know about mise — my tools are just available.

2. **Environment variables.** When the project's `mise.toml` is committed, I keep secrets and local config in `mise.local.toml`:

```toml
[env]
DATABASE_URL = "postgres://localhost/myapp_dev"
SECRET_KEY_BASE = "..."
```

Miser doesn't care how you structure this — it just calls `mise ls --current` and works with whatever tools are resolved for the current directory.

## Contributing

The registry is the main contribution surface. Each tool has its own file under `lua/miser/registry/`. To add support for a new tool:

1. Create a new file in `lua/miser/registry/` (e.g. `my_tool.lua`)
2. Return a table keyed by the exact `mise.toml` tool name with `lsp` and/or `formatter` config
3. Require the new file in `lua/miser/registry/init.lua`
4. For LSPs, ensure a matching config exists in nvim-lspconfig (most servers are already covered)
5. Test with a `mise.toml` that declares the tool
6. Open a PR

## License

MIT
