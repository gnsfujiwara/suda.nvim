-- Minimal init for testing
local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local suda_dir = vim.fn.fnamemodify(vim.fn.expand("<sfile>"), ":h:h")

vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(suda_dir)

vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/suda.lua")
