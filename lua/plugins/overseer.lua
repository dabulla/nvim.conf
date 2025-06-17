return {
  "stevearc/overseer.nvim",
  opts = {},
  config = function(_, opts)
    require("overseer").setup(opts)
    require("custom.overseer_msbuild")  -- 👈 register MSBuild templates
  end,
}