local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "rose-pine/neovim", name = "rose-pine", priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "main",
        styles = { italic = false, transparency = true },
      })
      vim.cmd.colorscheme("rose-pine")
    end,
  },
  { "junegunn/goyo.vim" },
  { "preservim/nerdtree" },
  { "mbbill/undotree" },
  { "tpope/vim-fugitive" },
  { "sakhnik/nvim-gdb" },
  { "hat0uma/csvview.nvim", opts = {} },
  { "neoclide/coc.nvim", branch = "release" },
  {
    "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate",
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "AckslD/nvim-neoclip.lua", dependencies = { "nvim-telescope/telescope.nvim" }, opts = {} },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "rose-pine" } },
  },
}, {
  -- don't nag about plugin updates on every start
  change_detection = { notify = false },
})
