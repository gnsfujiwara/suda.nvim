-- Luacheck configuration for suda.nvim

-- Only allow globals defined by Neovim
std = "luajit"
globals = { "vim" }

-- Ignore unused self arguments
self = false

-- Ignore line length
max_line_length = false

-- Ignore some pedantic warnings
ignore = {
  "212", -- Unused argument
  "213", -- Unused loop variable
  "631", -- Line is too long
}

-- Exclude directories
exclude_files = {
  ".tests/",
  "tests/minimal_init.lua",
}

-- Read globals from Neovim
read_globals = {
  "vim",
}

