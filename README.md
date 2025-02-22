# Miser

Miser is a Neovim plugin that manages development tools using [Mise](https://github.com/jdx/mise). It ensures that required tools are installed and available, automatically installing them when needed.

## Features

- **Auto-installation**: Automatically installs tools required by Neovim configurations.
- **Lazy-loading**: Installs tools on demand when an LSP server is started.
- **Manual Installation**: Install tools manually via the `:MiserInstall` command.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "carldaws/miser.nvim" }
```

## Commands

- `:MiserInstall <tool>` – Installs the specified tool.

## Configuration

Miser can be configured via `require("miser").setup({})` with the following options:

```lua
require("miser").setup({
    tools = { "gopls", "rust-analyzer" } -- These will be installed when needed
    ensure_installed = { "lua-language-server", "rubocop" }, -- List of tools to ensure are installed
})
```

## How It Works

1. On startup, Miser installs all tools listed in `ensure_installed`.
2. When Neovim starts an LSP client, Miser checks if the required tool is installed and installs it if necessary.
3. If Mise or the required dependencies are missing, Miser provides helpful error messages.

## Dependencies

- [Mise](https://github.com/jdx/mise) – Required for managing tools.
- Neovim 0.8+ (for `vim.lsp.start_client` API usage).

## License

MIT License

## Contributing

PRs are welcome! Feel free to contribute to Miser and help improve its functionality.

