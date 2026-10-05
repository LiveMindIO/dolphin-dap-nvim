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
