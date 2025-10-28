-- Example configuration for suda.nvim

require("suda").setup({
  prompt = "Password: ",
  smart_edit = true,
  -- noninteractive = true, -- Uncomment when passwordless sudo is configured
  -- command = "sudo.exe",   -- Override on Windows when necessary
})

local suda = require("suda")

-- Keymaps for quick access
vim.keymap.set("n", "<leader>sr", function()
  suda.read()
end, { desc = "[suda] Reopen current buffer with sudo" })

vim.keymap.set("n", "<leader>sw", function()
  suda.write()
end, { desc = "[suda] Write current buffer with sudo" })

-- Edit a specific system file with sudo
vim.keymap.set("n", "<leader>se", function()
  suda.read("/etc/hosts")
end, { desc = "[suda] Edit /etc/hosts with sudo" })

-- Custom helper that always escalates writes
vim.api.nvim_create_user_command("SudaWriteHosts", function()
  suda.write("/etc/hosts")
end, { desc = "Write /etc/hosts with sudo" })

-- Optional integration with telescope
local ok, telescope = pcall(require, "telescope.builtin")
if ok then
  vim.keymap.set("n", "<leader>sf", function()
    telescope.find_files({
      prompt_title = "Protected files",
      cwd = "/etc",
      attach_mappings = function(_, map)
        map("i", "<CR>", function(prompt_bufnr)
          local selection = require("telescope.actions.state").get_selected_entry()
          require("telescope.actions").close(prompt_bufnr)
          suda.read(selection.value)
        end)
        return true
      end,
    })
  end, { desc = "[suda] Browse protected files" })
end
