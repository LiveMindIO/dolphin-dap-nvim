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

print("Dolphin launch argument tests passed")
