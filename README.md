# Miser.nvim

**Miser** is a minimalist tool manager for Neovim users who prefer [mise](https://github.com/jdx/mise) over system-wide installs.

Miser ensures that project-required tools like formatters, linters and language servers are available in the project's environment.

If tools are missing, Miser automatically triggers their install process.

## Features

- Automatic tool and runtime installation for each project
- Seamless integration with mise
- Minimal setup: just list the tools you need
- Easily add support for new tools and runtimes / environments
- Works with any language server, formatter, linter or debugger

## How it works

1. Miser listens for `FileType` events
2. When you open a file, Miser checks if the necessary tools and runtimes are installed via mise
3. If a runtime or tool is missing, Miser installs it
4. Once installed, the tool and runtime is ready to use

## Installation

Using lazy.nvim:

```lua
{
    "carldaws/miser.nvim",
    config = function()
        require("miser").setup({
            tools = { "gopls", "rubocop", "prettier", "black", "zls" }
        })
    end
}
```

## Configuration

Just pass a table of `tools` to the setup function:

```lua
require("miser").setup({
    tools = { "gopls", "rubocop", "prettier", "black", "zls" }
})
```

Tools are defined in `lua/miser/tools/<tool-name>.lua` and consist of:

- Which filetype it applies to
- Which runtime(s) or environment(s) it requires (ruby, rust, go, zig, node, etc.)
- A command to verify the tool is installed
- A command to install the tool using mise

## Example tool definition

Here's what a typical Miser tool definition looks like:

```lua
return {
    requires = { "ruby" },
    filetypes = { "ruby" },
    commands = {
        install = "gem install rubocop",
        verify = "mise which rubocop",
    }
}
```

- `requires` - runtimes which must be available before installing the tool
- `filetypes` - Neovim filetypes this tool should be active for
- `commands.install` - A command used to install the tool if it's missing
- `commands.verify` - A command used to check if the tool is installed

## Contributing tools

**If you have a tool you think others would benefit from, please submit a PR**

Adding a new tool is simple:

1. Create a new file `lua/miser/tools/<my-new-tool>.lua`
2. Define the required runtime(s), filetypes and commands

That's it!

## Next up

- Enable auto-install (no prompting) by default
- Add tool type (LSP, linter, debugger etc.) to tool definitions to allow for smart post-install behaviour such as reattaching LSPs
- Allow multiple install commands to support different environments for the same tool (Bun vs Node, for example)
