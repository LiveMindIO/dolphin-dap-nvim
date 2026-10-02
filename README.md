# Dolphin DAP for Neovim

[nvim-dap](https://github.com/mfussenegger/nvim-dap) can connect to a running Dolphin
server directly or use this plugin to start Dolphin.

Development is hosted on Forgejo and mirrored publicly to
[GitHub](https://github.com/LiveMindIO/dolphin-dap-nvim).

## Requirements

Install `nvim-dap` with your preferred plugin manager.

## Basic Attach Configuration

This minimal configuration connects to Dolphin on TCP port `5678` without this plugin:

```lua
local dap = require("dap")

dap.adapters.dolphin = {
  type = "server",
  host = "127.0.0.1",
  port = 5678,
}

local config = {
  name = "Attach to Dolphin",
  type = "dolphin",
  request = "attach",
}

for _, language in ipairs({ "c", "cpp" }) do
  dap.configurations[language] = dap.configurations[language] or {}
  table.insert(dap.configurations[language], config)
end
```

Start Dolphin using one of the commands in the
[server documentation](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/README.md#running-the-server),
then use `:DapContinue` and select **Attach to Dolphin**.

## Plugin Installation

The plugin can start Dolphin, resolve source paths, and create several
launch and attach configurations. Its optional default debugger interface uses
[`nvim-dap-ui`](https://github.com/rcarriga/nvim-dap-ui) and
[`nvim-nio`](https://github.com/nvim-neotest/nvim-nio).

With `lazy.nvim`:

```lua
{
  "LiveMindIO/dolphin-dap-nvim",
  dependencies = { "mfussenegger/nvim-dap" },
  config = function()
    require("dolphin-dap").setup()
  end,
}
```

Use your preferred plugin manager or Neovim configuration layout. No particular keymaps
are required. If you do not use `nvim-dap-ui`, initialize with:

```lua
require("dolphin-dap").setup({ setup_dap_ui = false })
```

A portable `lazy.nvim` example is available in [`lazy-dolphin-dap.lua`](lazy-dolphin-dap.lua).

## Project Configuration

Copy [`.dolphin-dap.example.lua`](.dolphin-dap.example.lua) to `.dolphin-dap.lua` in
the root of the project you want to debug.

For a fully linked decomp build, configure both the ELF and ISO:

```lua
return {
  dolphin = "/path/to/dolphin-emu-nogui",
  program = "/path/to/main.elf",
  disc = "/path/to/game.iso",
  source_paths = {
    "/path/to/project/src",
  },
  enable_cheats = false,
}
```

The ISO supplies the game files and disc environment. Dolphin ignores the ISO's DOL and
executes the ELF, whose symbols and DWARF match the running code.

For a partially decompiled project, run the ISO's DOL and use an address-matching ELF as
a metadata sidecar:

```lua
return {
  dolphin = "/path/to/dolphin-emu-nogui",
  program = "/path/to/game.iso",
  elf = "/path/to/main.elf",
  source_paths = {
    "/path/to/project/src",
  },
}
```

The sidecar does not replace the ISO's DOL. Use it only when its code and data addresses
exactly match the running DOL.

Source stepping and locals are unreliable in optimized source files. Build the files you
need to inspect without optimization; unrelated files can remain optimized.

## Starting a Session

Use `:DapContinue` or another standard `nvim-dap` command and select one of the registered
Dolphin configurations. Define keymaps using the normal `nvim-dap` functions if desired.

To start Dolphin separately, use a command from the
[server documentation](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/README.md#running-the-server),
then select the Dolphin attach configuration in Neovim. `:DolphinDapCmd` prints and
copies a command generated from the current `.dolphin-dap.lua` file.

Every Dolphin debugging launch needs this CLI override:

```bash
-C Dolphin.Interface.DebugModeEnabled=True
```

When starting Dolphin separately, add it to the command printed by `:DolphinDapCmd`
before attaching. A DAP port or socket alone does not enable core breakpoint checks
and debugger-aware stepping. The plugin's generated launch command does not currently
include this override. For plugin-managed launches, enable it in the `Dolphin.ini`
used by that process:

```ini
[Interface]
DebugModeEnabled = True
```

The CLI override is launch-local; the INI setting persists. Neither opens GUI panes
in the NoGUI build.

The configuration supports:

- `dolphin`: path to `dolphin-emu-nogui`.
- `dolphin_gui`: optional path to the Qt Dolphin executable.
- `program`: ELF, DOL, or ISO to execute.
- `disc`: ISO mounted while executing an ELF or DOL.
- `elf`: metadata-only debug ELF for the executable selected by `program`.
- `source_paths`: ordered directories used to locate source files; spawned Dolphin instances also
  receive them through the global `Dolphin.Debug.SourcePaths` setting.
- `host` and `port`: TCP attach address, defaulting to `127.0.0.1:5678`.
- `socket`: Unix socket path for local attach.
- `platform`: video platform for the NoGUI executable.
- `enable_cheats`: whether saved cheats are enabled for this launch.
- `cwd`: optional Dolphin working directory.

See [Source debugging with DWARF](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/README.md#source-debugging-with-dwarf)
for the difference between executed and sidecar ELFs.
