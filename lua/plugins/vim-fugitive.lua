-- ~/.config/nvim/lua/plugins/fugitive.lua
return {
  "tpope/vim-fugitive",
  keys = {
    -- The "<cmd>" is a slightly more robust way to call commands in mappings.
    { "<leader>gs", "<cmd>Git<CR>", desc = "Fugitive: Git Status" },
    { "<leader>gc", "<cmd>Git commit<CR>", mode = "n", desc = "Fugitive: Git Commit" },
    { "<leader>gp", "<cmd>Git push<CR>", mode = "n", desc = "Fugitive: Git Push" },
    { "<leader>gl", "<cmd>Git pull<CR>", mode = "n", desc = "Fugitive: Git Pull" },
    { "<leader>gb", "<cmd>Git blame<CR>", mode = "n", desc = "Fugitive: Git Blame" },
    { "<leader>gd", "<cmd>Gvdiffsplit<CR>", mode = "n", desc = "Fugitive: Git Diff" },
    
    -- Example of a keymap that works in both Normal and Visual mode
    { "<leader>gh", ":Git log<CR>", mode = {"n", "v"}, desc = "Fugitive: Git Log" },
  },
}