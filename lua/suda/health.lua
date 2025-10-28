local config = require("suda.config")
local util = require("suda.util")

local M = {}

local function check_command()
  local command = config.command()
  if util.has_sudo() then
    vim.health.ok(("Elevation command available: %s"):format(command))
  else
    vim.health.error(
      ("No executable found for `%s`. Install sudo or configure `require('suda').setup({ command = 'path/to/sudo' })`."):format(
        command
      ),
      {
        "On Windows, install mattn/sudo or configure a compatible command (such as gsudo) and set `noninteractive = true`.",
      }
    )
  end

  if not util.supports_stdin() then
    vim.health.info(
      ("Command `%s` cannot read passwords from stdin. Enable `noninteractive = true` or pick a compatible executable."):format(
        command
      )
    )
  end
end

local function check_version()
  if vim.fn.has("nvim-0.8.0") == 1 then
    vim.health.ok("Neovim >= 0.8.0")
  else
    vim.health.warn("Neovim < 0.8.0", {
      "suda.nvim requires Neovim 0.8.0 or newer.",
      "Upgrade Neovim for full functionality.",
    })
  end
end

local function check_config()
  if config.is_initialized() then
    vim.health.ok("Configuration loaded via require('suda').setup()")
  else
    vim.health.warn("Configuration uses defaults", {
      "Call require('suda').setup() to customise behaviour.",
    })
  end

  if config.options.noninteractive then
    vim.health.warn("noninteractive mode enabled", {
      "sudo will run with -n and fail if a password is required.",
      "Ensure your sudoers configuration allows passwordless access.",
    })
  end

  if config.options.smart_edit then
    vim.health.ok("smart_edit enabled")
  else
    vim.health.info("smart_edit disabled (enable with require('suda').setup({ smart_edit = true }))")
  end
end

---Check health of suda.nvim
function M.check()
  vim.health.start("suda.nvim")
  check_version()
  check_command()
  check_config()
end

return M
