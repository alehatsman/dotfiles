-- claude-nvim-plugin.lua
-- Example plugin specification for lazy.nvim
-- Copy this to your plugins directory (e.g., lua/plugins/claude-nvim.lua)

return {
  "claude_nvim",
  -- Point to the plugin directory in your dotfiles
  dir = vim.fn.expand("~/.config/nvim/lua/claude_nvim"),

  dependencies = {
    "ibhagwan/fzf-lua",
  },

  config = function()
    require("claude_nvim").setup({
      auto_start = true,      -- Automatically spawn session on VimEnter
      default_model = "sonnet", -- Default model: "sonnet", "opus", "haiku"
    })
  end,

  -- Optional: lazy load on keymap or command
  -- keys = {
  --   { "<Space>cw", desc = "Claude: Pick session" },
  -- },

  -- Or load immediately
  lazy = false,
}
