local config = require("suda.config")

local uv = vim.uv or vim.loop
local fn = vim.fn
local log = vim.log.levels

local M = {}

local function supports_stdin(command)
  command = (command or ""):lower()
  if command:find("gsudo", 1, true) then
    return false
  end
  return command:find("sudo", 1, true) ~= nil
end

local function to_lines(output)
  if not output or output == "" then
    return {}
  end
  local lines = vim.split(output, "\n", { plain = true })
  if output:sub(-1) == "\n" then
    table.remove(lines)
  end
  return lines
end

local function fs_access(path, mode)
  if not path or path == "" then
    return false
  end
  if uv and uv.fs_access then
    local ok, result = pcall(uv.fs_access, path, mode)
    if ok then
      return result and true or false
    end
  end
  if mode == "R" then
    return fn.filereadable(path) == 1
  elseif mode == "W" then
    local writable = fn.filewritable(path)
    return writable == 1 or writable == 2
  end
  return false
end

---Return true when an elevation command is available.
---@return boolean
function M.has_sudo()
  return config.has_command()
end

---Check if the current command supports reading the password from stdin.
---@return boolean
function M.supports_stdin()
  return supports_stdin(config.command())
end

---Build the sudo command with appropriate flags.
---@param opts? {noninteractive?: boolean, prompt?: string}
---@return string[]
function M.get_sudo_cmd(opts)
  opts = opts or {}
  local command = config.command()
  local cmd = { command }
  local prompt = opts.prompt or config.options.prompt or ""

  if opts.noninteractive then
    if supports_stdin(command) then
      table.insert(cmd, "-n")
    end
  else
    if supports_stdin(command) then
      vim.list_extend(cmd, { "-S", "-p", prompt })
    end
  end

  return cmd
end

---Convert a suda:// path to a regular path.
---@param path string
---@return string
function M.from_suda_path(path)
  if not path then
    return ""
  end
  return path:gsub("^suda://", "", 1)
end

---Normalize a filesystem path.
---@param path string
---@return string
function M.normalize_path(path)
  if not path or path == "" then
    return ""
  end
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(path)
  end
  return fn.fnamemodify(path, ":p")
end

---Convert a regular path to a suda:// path.
---@param path string
---@return string
function M.to_suda_path(path)
  if not path or path == "" then
    return path
  end
  if path:match("^suda://") then
    return path
  end
  return "suda://" .. M.normalize_path(path)
end

---Escape a path for :edit/:write commands.
---@param path string
---@return string
function M.escape_path(path)
  return fn.fnameescape(path)
end

---Check if a file is readable.
---@param path string
---@return boolean
function M.is_readable(path)
  return fs_access(path, "R")
end

---Check if a file or directory is writable.
---@param path string
---@return boolean
function M.is_writable(path)
  return fs_access(path, "W")
end

---Prompt for a password using inputsecret.
---@param prompt string
---@return string?
function M.get_password(prompt)
  local ok, password = pcall(fn.inputsecret, prompt)
  if not ok then
    return nil
  end
  if password == "" then
    return nil
  end
  return password
end

---Execute a system command and return the output.
---@param cmd string[]
---@param input? string
---@param opts? {text?: boolean}
---@return string[]|string, integer, string
function M.system(cmd, input, opts)
  opts = opts or {}
  local text = opts.text ~= false

  if vim.system then
    local ok, job = pcall(vim.system, cmd, {
      stdin = input,
      text = text,
    })
    if not ok then
      return text and {} or "", 1, tostring(job)
    end
    local result = job:wait()
    local stdout = result.stdout or ""
    local stderr = result.stderr or ""
    local code = result.code
    if code == nil then
      code = result.signal or 0
    end

    if text then
      stdout = to_lines(stdout)
    end

    return stdout, code, stderr
  end

  local stdout
  if input ~= nil then
    if text then
      stdout = fn.systemlist(cmd, input)
    else
      stdout = fn.system(cmd, input)
    end
  else
    if text then
      stdout = fn.systemlist(cmd)
    else
      stdout = fn.system(cmd)
    end
  end

  local code = vim.v.shell_error
  return stdout, code, ""
end

---Trim whitespace from both ends of a string.
---@param text string?
---@return string
function M.trim(text)
  if not text then
    return ""
  end
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

---Send a namespaced notification.
---@param message string
---@param level integer
function M.notify(message, level)
  vim.notify(message, level or log.INFO, { title = "suda.nvim" })
end

return M
