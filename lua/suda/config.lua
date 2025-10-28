---@class suda.Config
---@field prompt string Prompt string for password input
---@field smart_edit boolean Automatically switch to suda:// for protected files
---@field noninteractive boolean Use sudo without password prompt (use at your own risk)
---@field command? string Custom executable used to elevate permissions (falls back to auto-detect)

---@class suda.Runtime
---@field command string
---@field available boolean Whether the detected command can be executed

local uv = vim.uv or vim.loop

local M = {}

---@type suda.Config
M.defaults = {
  prompt = "Password: ",
  smart_edit = false,
  noninteractive = false,
  command = nil,
}

---@type suda.Config
M.options = vim.deepcopy(M.defaults)

---@type suda.Runtime
M.runtime = {
  command = "sudo",
  available = false,
}

M._initialized = false

local function tbl_contains(tbl, value)
  for _, item in ipairs(tbl) do
    if item == value then
      return true
    end
  end
  return false
end

local function detect_command(preferred)
  local candidates = {}

  if preferred and preferred ~= "" then
    table.insert(candidates, preferred)
  end

  local defaults = { "sudo", "sudo.exe", "gsudo", "gsudo.exe" }
  for _, cmd in ipairs(defaults) do
    if not tbl_contains(candidates, cmd) then
      table.insert(candidates, cmd)
    end
  end

  for _, cmd in ipairs(candidates) do
    if vim.fn.executable(cmd) == 1 then
      return cmd, true
    end
    if uv and uv.fs_stat then
      local ok, stat = pcall(uv.fs_stat, cmd)
      if ok and stat then
        return cmd, true
      end
    end
  end

  return candidates[1] or "sudo", false
end

local function validate(options)
  vim.validate({
    prompt = { options.prompt, "string" },
    smart_edit = { options.smart_edit, "boolean" },
    noninteractive = { options.noninteractive, "boolean" },
    command = {
      options.command,
      function(value)
        return value == nil or type(value) == "string"
      end,
      "string or nil",
    },
  })
end

local function refresh_runtime()
  local command, available = detect_command(M.options.command)
  M.runtime.command = command
  M.runtime.available = available
end

---@return suda.Config
local function copy_defaults()
  return vim.deepcopy(M.defaults)
end

---Setup configuration
---@param opts? suda.Config
function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", copy_defaults(), opts)
  validate(M.options)
  refresh_runtime()
  M._initialized = true
end

---@return string
function M.command()
  return M.runtime.command
end

---@return boolean
function M.has_command()
  return M.runtime.available
end

---@return boolean
function M.is_initialized()
  return M._initialized
end

refresh_runtime()

return M
