return {
  {
    "https://git.jacoby6000.com/LiveMindIO/dolphin-dap-nvim",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      require("dolphin-dap").setup()
    end,
  },
}
