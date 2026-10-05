-- Run from the repository root: nvim --headless -u NONE -l tests/launch_args.lua
vim.opt.runtimepath:append(vim.fn.getcwd())

local dap = { adapters = {} }
package.loaded.dap = dap
local dolphin = require("dolphin-dap")
dolphin.find_project_config = function()
  return { program = "/games/melee.iso" }
end
dolphin.register_adapter()

local override = "Dolphin.Interface.DebugModeEnabled=True"
local function assert_debug_mode(args)
  local count = 0
  for i, arg in ipairs(args) do
    if arg == override then
      assert(args[i - 1] == "-C", "debug mode must be a CLI config override")
      count = count + 1
    end
  end
  assert(count == 1, "every launch must enable debug mode exactly once")
end

local launches = 0
for _, config in ipairs(dolphin.build_configurations({ program = "/games/melee.iso" })) do
  local adapter
  dap.adapters.dolphin(function(value)
    adapter = value
  end, config)
  assert(adapter, "adapter callback must run")
  if config.request == "launch" or config.spawn then
    assert_debug_mode(adapter.executable.args)
    assert(vim.tbl_contains(adapter.executable.args, "Dolphin.General.DAPSocket="))
    assert(vim.tbl_contains(adapter.executable.args, "Dolphin.Debug.ReplaceDiscExecutable=true"))
    assert(adapter.host == "127.0.0.1")
    launches = launches + 1
  else
    assert(adapter.executable == nil, "plain attach must not spawn Dolphin")
  end
end
assert(launches == 5, "cover headless, NoGUI video, Qt, and both spawn configurations")

for _, opts in ipairs({ {}, { platform = "x11" }, { nogui = false } }) do
  local command = assert(dolphin.shell_command(opts))
  assert(command:find(override, 1, true), "manual command must enable debug mode")
end

local function launch_adapter(project, overrides)
  dolphin.find_project_config = function() return project end
  local adapter
  dap.adapters.dolphin(function(value) adapter = value end,
    vim.tbl_extend("force", { request = "launch", nogui = true }, overrides or {}))
  return assert(adapter)
end

local project = {
  dolphin = "C:/Tools/Dolphin/dolphin-emu-nogui.exe",
  program = "C:/Games/melee.iso",
  elf_file = "C:/Build/main.elf",
  source_paths = { "C:/Source One", "C:/Source Two" },
  enable_cheats = false,
  host = "192.0.2.1",
}
local adapter = launch_adapter(project)
local args = adapter.executable.args
assert(vim.tbl_contains(args, "Dolphin.General.DAPSocket="), "TCP launch must clear saved socket")
assert(vim.tbl_contains(args, "Dolphin.Debug.ReplaceDiscExecutable=true"), "replacement defaults to true")
assert(vim.tbl_contains(args, "Dolphin.Debug.ELFFile=C:/Build/main.elf"))
assert(vim.tbl_contains(args, "Dolphin.Debug.SourcePaths=C:/Source One;C:/Source Two"))
assert(vim.tbl_contains(args, "Dolphin.Core.EnableCheats=false"))
assert(adapter.host == "127.0.0.1", "spawned Dolphin must use loopback, not the attach host")
adapter = launch_adapter(project, { nogui = false })
assert(adapter.executable.command == "C:/Tools/Dolphin/dolphin-emu.exe", "derive the Windows Qt binary")
assert(not vim.tbl_contains(adapter.executable.args, "--platform"), "Qt must omit --platform")
adapter = launch_adapter(project, { replace_disc_executable = false })
assert(vim.tbl_contains(adapter.executable.args, "Dolphin.Debug.ReplaceDiscExecutable=false"))
adapter = launch_adapter(project, { program = "C:/Build/main.elf", disc = "C:/Games/melee.iso" })
assert(vim.tbl_contains(adapter.executable.args, "Dolphin.Core.DefaultISO=C:/Games/melee.iso"))
assert(vim.tbl_contains(adapter.executable.args, "Dolphin.Debug.ReplaceDiscExecutable=true"))

local attached
dap.adapters.dolphin(function(value) attached = value end,
  { request = "attach", host = "192.0.2.1", port = 5678 })
assert(attached.host == "192.0.2.1" and attached.executable == nil, "remote attach remains supported")

print("Dolphin launch compatibility tests passed")
