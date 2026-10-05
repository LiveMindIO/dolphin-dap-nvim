# Dolphin DAP for Neovim

This plugin configures [nvim-dap](https://github.com/mfussenegger/nvim-dap) to launch
or attach to Dolphin's DAP server.

# Pre-requisites

- Neovim with `vim.fs` support (0.10 or newer).
- `nvim-dap` and a current [Dolphin DAP build](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/README.md).
- A legally obtained game image, a debug ELF with symbols and DWARF, and its source files for source debugging.
- Optional: `nvim-dap-ui` and `nvim-nio` for the debugger interface.

# Installation

Using `lazy.nvim`:

```lua
{
  "LiveMindIO/dolphin-dap-nvim",
  dependencies = {
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    require("dolphin-dap").setup()
  end,
}
```

Without `nvim-dap-ui`, install only `nvim-dap` and initialize with:

```lua
require("dolphin-dap").setup({ setup_dap_ui = false })
```

The complete plugin specification is in [`lazy-dolphin-dap.lua`](lazy-dolphin-dap.lua).

# Configuration

## Configure Melee

Create `.dolphin-dap.lua` in the Melee project root:

```lua
return {
  dolphin = "~/projects/dolphin-dap/build/Binaries/dolphin-emu-nogui",
  program = "~/games/melee.iso",
  elf_file = "~/projects/melee/build/GALE01/main.elf",
  replace_disc_executable = true,
  cwd = "~/projects/melee",
  source_paths = {
    "~/projects/melee/src",
    "~/projects/melee/extern/dolphin/src",
  },
  enable_cheats = false,
  port = 5678,
}
```

Change the Dolphin, Melee, and ISO paths for your machine. Dolphin boots the ISO through
its normal disc bootstrap, then replaces its DOL with the configured ELF. Keep
`source_paths` ordered as shown so Dolphin can resolve basename-only MWCC paths such as
`__start.c`.

The same configuration is available as [`.dolphin-dap.example.lua`](.dolphin-dap.example.lua).

## Use

- Run `:DapContinue` and select a Dolphin launch configuration.
- Run `:lua require("dolphin-dap").attach()` to attach to Dolphin on the configured port.
- Run `:DolphinDapCmd` to print and copy the equivalent Dolphin command.

When this plugin starts Dolphin, it passes `source_paths` through
`Dolphin.Debug.SourcePaths`. Use the command printed by `:DolphinDapCmd` when starting
Dolphin separately.

The plugin automatically includes this CLI override in all launch/spawn configurations
and the command printed by `:DolphinDapCmd`:

```bash
-C Dolphin.Interface.DebugModeEnabled=True
```

When writing your own launch command, include this override before attaching. A DAP
port or socket alone does not enable core breakpoint checks and debugger-aware
stepping. The override applies only to that launch and does not open GUI panes in
the NoGUI build.

## Options

- `dolphin`: path to `dolphin-emu-nogui`.
- `dolphin_gui`: optional path to the Qt Dolphin executable.
- `program`: ELF, DOL, or ISO to boot.
- `elf_file`: ELF loaded for symbols and DWARF, and optionally executed in place of a disc's DOL.
- `replace_disc_executable`: replace a booted disc's DOL with `elf_file`. It also enables the
  disc bootstrap when `program` is an ELF or DOL and `disc` is set.
- `disc`: optional ISO mounted while directly executing an ELF or DOL.
- `elf`: deprecated alias for `elf_file` retained for existing project files.
- `source_paths`: ordered directories used to locate source files; spawned Dolphin instances also
  receive them through the global `Dolphin.Debug.SourcePaths` setting.
- `host` and `port`: TCP attach address, defaulting to `127.0.0.1:5678`.
- `socket`: Unix socket path for local attach.
- `platform`: video platform for the NoGUI executable.
- `enable_cheats`: whether saved cheats are enabled for this launch.
- `cwd`: optional Dolphin working directory.

See the [Dolphin DAP server documentation](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/README.md)
for build commands, server settings, and DWARF limitations.
