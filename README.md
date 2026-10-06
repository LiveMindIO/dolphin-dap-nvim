# Dolphin DAP for Neovim

This plugin configures [nvim-dap](https://github.com/mfussenegger/nvim-dap) to launch
or attach to Dolphin's DAP server.

# Pre-requisites

- Neovim with `vim.fs` support (0.10 or newer).
- `nvim-dap` and a current [Dolphin DAP build](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/README.md).
- A legally obtained game image. For typed source debugging, use a debug ELF with
  MWCC/CodeWarrior DWARF 1.1 and its matching source files; arbitrary GCC/Clang ELFs
  with modern DWARF are not a substitute. See the
  [debug-information limits](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/README.md#debug-information-limits).
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

Without `nvim-dap-ui`, keep this plugin and `nvim-dap`, remove the UI dependencies,
and use this `lazy.nvim` specification instead:

```lua
{
  "LiveMindIO/dolphin-dap-nvim",
  dependencies = { "mfussenegger/nvim-dap" },
  config = function()
    require("dolphin-dap").setup({ setup_dap_ui = false })
  end,
}
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
    "~/projects/melee/libs/dolphin/src",
  },
  enable_cheats = false,
  port = 5678,
}
```

Change the Dolphin, Melee, and ISO paths for your machine. Dolphin boots the ISO through
its normal disc bootstrap, then replaces its DOL with the configured ELF. Keep
`source_paths` ordered as shown so Dolphin can resolve basename-only MWCC paths such as
`__start.c`.

Build current upstream Melee with `python3 configure.py --debug` followed by `ninja`.
Use `python` on Windows if that is your Python command. Older checkouts may use
`extern/dolphin/src` rather than `libs/dolphin/src`; source roots must match the
checkout used to build the ELF.

The same configuration is available as [`.dolphin-dap.example.lua`](.dolphin-dap.example.lua).

On Windows, set `dolphin` to your built `DolphinNoGUI.exe`, set
`dolphin_gui` explicitly to `Dolphin.exe` if using Qt, and use `platform = "win32"`.
Use absolute paths such as `C:/tools/dolphin-dap/DolphinNoGUI.exe`.

## Use

- Run `:DapContinue` and select **Dolphin launch nogui (video, …)** for a game window,
  **Dolphin launch headless** for no window, or **Dolphin launch (Qt)** for the Qt binary.
- Run `:lua require("dolphin-dap").attach()` to attach to Dolphin on the configured port.
- Run `:DolphinDapCmd` to print and copy the equivalent Dolphin command.

The Qt launch requires a separate Qt-enabled Dolphin build. For build instructions
and using its native source debugger, see the
[Qt source-debugging guide](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/qt-source-debugging.md).

### First source breakpoint

1. Open a source file from the checkout used to build the ELF. Move to an executable
   line and run `:DapToggleBreakpoint`.
2. Run `:DapContinue` and select a launch configuration. The initial stop may show
   startup disassembly; run `:DapContinue` again to reach your breakpoint, performing
   the relevant action in the game if needed.
3. Use `:DapStepOver`, `:DapStepInto`, and `:DapStepOut` to step. With `nvim-dap-ui`,
   inspect **Scopes** and **Stacks**; without it, open `:DapToggleRepl` and evaluate
   expressions such as `r3`. Locals are available for the top frame only.
4. Run `:DapDisconnect` to disconnect. For a plain attach, Dolphin was started
   separately and remains running; stop that process yourself when finished.

If a breakpoint is unverified, choose a line with executable code and check that
the ELF was built from this checkout with debug information enabled.

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

Launch/spawn configurations always use local TCP and clear a saved `DAPSocket` setting.
Normal launches allocate a port automatically; attach-with-spawn uses `port`.
`host` is used only for attaching to an existing server. Plain attach does not start
Dolphin or change its boot configuration. Configure its ELF, replacement mode,
source roots, and core debugging before connecting.

## Options

- `dolphin`: path to `dolphin-emu-nogui` (`DolphinNoGUI.exe` on Windows).
- `dolphin_gui`: optional path to the Qt Dolphin executable.
- `program`: ELF, DOL, or ISO to boot.
- `elf_file`: ELF loaded for symbols and DWARF, and optionally executed in place of a disc's DOL.
- `replace_disc_executable`: defaults to `true`, matching the VS Code plugin. Replace a
  booted disc's DOL with `elf_file`; set `false` for metadata-only debugging, where ELF
  addresses must match the running executable. It also enables the
  disc bootstrap when `program` is an ELF or DOL and `disc` is set.
- `disc`: optional ISO mounted while directly executing an ELF or DOL.
- `elf`: deprecated alias for `elf_file` retained for existing project files.
- `source_paths`: ordered directories used to locate source files; spawned Dolphin instances also
  receive them through the global `Dolphin.Debug.SourcePaths` setting.
- `host` and `port`: TCP attach address, defaulting to `127.0.0.1:5678`.
- `socket`: Unix socket path for local attach.
- `platform`: NoGUI platform (`x11`, `win32`, `macos`, or `headless`, as supported by
  your build). `auto` or `video` selects the OS default. Qt configurations omit this flag.
- `entrypoints`: optional existing `entrypoints.json` sidecar; otherwise the plugin
  looks beside the debug ELF. Passed through the supported `--debug-entrypoints` flag.
- `enable_cheats`: whether saved cheats are enabled for this launch.
- `cwd`: optional Dolphin working directory.

Use absolute paths (or `~` paths, which the plugin expands) for the executable,
game, ELF, and source roots. `cwd` changes Dolphin's working directory, not the
base used to expand paths in Neovim.

The plugin uses `Dolphin.Debug.ELFFile`, `Dolphin.Debug.ReplaceDiscExecutable`, and
`Dolphin.Debug.SourcePaths`. It does not use the removed `DwarfElf` or
`BootExecutableWithDefaultDisc` settings. These launch overrides are not persisted.

See the [Dolphin DAP server documentation](https://github.com/LiveMindIO/dolphin-dap/blob/master/Tools/dap/README.md)
for build commands, server settings, and DWARF limitations.
