---@class Suda
---@field config suda.Config
local M = {}

local config = require("suda.config")
local core = require("suda.core")
local util = require("suda.util")
local log = vim.log.levels

---Setup suda.nvim
---@param opts? suda.Config
function M.setup(opts)
  config.setup(opts)
  core.setup_protocol()
  core.setup_smart_edit()
end

---Read current file or specified file with sudo
---@param path? string
function M.read(path)
  local target = path
  if not target or target == "" then
    target = vim.api.nvim_buf_get_name(0)
    if target == "" then
      util.notify("suda.nvim: no file associated with the current buffer", log.ERROR)
      return
    end
  else
    target = vim.fn.fnamemodify(target, ":p")
  end

  if not target:match("^suda://") then
    target = util.to_suda_path(target)
  end

  local command = "edit"
  if vim.bo.modified then
    command = "confirm edit"
  end

  vim.cmd(("keepalt %s %s"):format(command, util.escape_path(target)))
end

---Write current file or specified file with sudo
---@param path? string
function M.write(path)
  local target = path
  if not target or target == "" then
    target = vim.api.nvim_buf_get_name(0)
    if target == "" then
      util.notify("suda.nvim: no file to write", log.ERROR)
      return
    end
  else
    target = vim.fn.fnamemodify(target, ":p")
  end

  local current = vim.api.nvim_buf_get_name(0)
  local encoded_target = target
  if not encoded_target:match("^suda://") then
    encoded_target = util.to_suda_path(encoded_target)
  end

  if current ~= "" and not current:match("^suda://") then
    current = util.to_suda_path(current)
  end

  if current == encoded_target or (current ~= "" and current:match("^suda://")) then
    core.write(encoded_target)
    return
  end

  vim.cmd(("keepalt write %s"):format(util.escape_path(encoded_target)))
end

return M
