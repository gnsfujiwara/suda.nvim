# suda.nvim

`suda.nvim` lets you read and write files from Neovim using elevated privileges without leaving your current session. The plugin is inspired by [lambdalisue/vim-suda](https://github.com/lambdalisue/vim-suda), but is reimplemented in pure Lua with a structure similar to Folke's modern Neovim plugins.

## Highlights

- Works entirely in Lua and targets Neovim 0.8+
- Provides the `suda://` protocol for editing protected files transparently
- Offers smart detection to reopen files with sudo when they are not writable
- Integrates with `:checkhealth` for quick diagnostics
- Exposes a small Lua API for custom workflows
- Supports configurable prompts, passwordless sudo, and custom elevation commands

## Installation

### lazy.nvim

```lua
{
  "gnsfujiwara/suda.nvim",
  event = "VeryLazy",
  opts = {
    -- Optional overrides go here
  },
}
```

### packer.nvim

```lua
use {
  "gnsfujiwara/suda.nvim",
  config = function()
    require("suda").setup()
  end,
}
```

### plain setup

```lua
require("suda").setup()
```

Call `setup()` early in your configuration so the autocommands and commands are registered.

## Configuration

All options are optional; omitting them keeps the defaults.

```lua
require("suda").setup({
  prompt = "Password: ",    -- Prompt used when asking for a password
  smart_edit = false,       -- Automatically switch to suda:// for protected files
  noninteractive = false,   -- Use sudo -n (only if your sudoers allows passwordless execution)
  command = nil,            -- Override the executable used for elevation
})
```

- `prompt`: customises the text shown in the password prompt.
- `smart_edit`: when enabled, files that require elevation are reopened automatically using the `suda://` protocol.
- `noninteractive`: adds `-n` to sudo so commands fail instead of prompting. Only use this if passwordless sudo is configured for the relevant commands.
- `command`: sets a concrete executable (for example `"sudo.exe"` on Windows). When left as `nil`, `suda.nvim` attempts to detect a suitable command automatically.

You can re-run `setup()` at any time; autocommands are refreshed with the new configuration.

## Usage

### Commands

- `:SudaRead [path]` — reopen the current buffer or the given path using sudo.  
- `:SudaWrite [path]` — write the current buffer, optionally to another path, using sudo.

Both commands accept relative and absolute paths. When no path is passed they operate on the current buffer.

### `suda://` protocol

You can work with the protocol directly:

```vim
:edit suda:///etc/hosts
:write suda:///etc/profile
```

The plugin registers `BufReadCmd` and `BufWriteCmd` handlers that transparently pipe data through sudo.

### Lua API

```lua
local suda = require("suda")

suda.read("/etc/hosts")
suda.write("/etc/hosts")
```

The API mirrors the commands and can be used to compose custom workflows or keymaps.

### Smart edit

Enable `smart_edit` to let the plugin reopen protected files automatically:

```lua
require("suda").setup({ smart_edit = true })
```

When Neovim attempts to load or create a file that is not readable or writable, `suda.nvim` schedules a reopen via `suda://` so your edits succeed without manual intervention.

## Noninteractive mode

If your sudoers file allows passwordless sudo for the commands `suda.nvim` runs, you can opt-in to noninteractive mode:

```lua
require("suda").setup({
  noninteractive = true,
})
```

This adds `-n` to the elevation command so Neovim never waits for a password prompt. Use this only when you are confident your environment is configured correctly.

## Windows support

Install an elevated command that provides sudo-like behaviour, such as:

- [mattn/sudo](https://github.com/mattn/sudo)
- [gerardog/gsudo](https://github.com/gerardog/gsudo)

Then configure `command` when necessary:

```lua
require("suda").setup({
  command = "sudo.exe",
  prompt = "Administrator password: ",
})
```

If your chosen command cannot read passwords from stdin, also set `noninteractive = true` and configure passwordless execution.

## Health check

Run `:checkhealth suda` to verify:

- The elevation command detected by the plugin
- Whether stdin password prompts are supported
- Your Neovim version
- Current configuration flags

The report includes remediation steps when something is missing.

## Tests

Automated tests are implemented with plenary.nvim. Clone plenary locally and either

```bash
git clone https://github.com/nvim-lua/plenary.nvim \
  "$HOME/.local/share/nvim/site/pack/vendor/start/plenary.nvim"
```

or set the `PLENARY_DIR` environment variable to point at an existing clone. After
that you can run:

```bash
make test
```

The Makefile exports `PLENARY_DIR` for the test harness automatically.

## Requirements

- Neovim 0.8 or newer
- An executable that can elevate privileges (`sudo`, `sudo.exe`, `gsudo`, and similar)

## Contributing

Pull requests, issues, and discussions are welcome. Please open an issue before implementing large changes so we can align expectations.

## License

MIT © gnsfujiwara

## Credits

- [vim-suda](https://github.com/lambdalisue/vim-suda) for the original concept
- [folke](https://github.com/folke) for inspiring the project layout and coding style
