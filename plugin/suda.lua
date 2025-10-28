-- Prevent loading plugin twice
if vim.g.loaded_suda then
  return
end
vim.g.loaded_suda = true

-- Initialize with default config if not already setup
local suda = require("suda")
if not require("suda.config").is_initialized() then
  suda.setup()
end

-- Create user commands
vim.api.nvim_create_user_command("SudaRead", function(opts)
  suda.read(opts.args)
end, {
  nargs = "?",
  complete = "file",
  desc = "Read a file with sudo privileges",
})

vim.api.nvim_create_user_command("SudaWrite", function(opts)
  suda.write(opts.args)
end, {
  nargs = "?",
  complete = "file",
  desc = "Write a file with sudo privileges",
})
