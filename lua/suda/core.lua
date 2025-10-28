local util = require("suda.util")
local config = require("suda.config")

local log = vim.log.levels
local uv = vim.uv or vim.loop

local M = {}

local function report_error(message)
  util.notify(message, log.ERROR)
  vim.api.nvim_err_writeln(message)
end

local function ensure_command(needs_prompt)
  if not util.has_sudo() then
    report_error(
      ("suda.nvim: no elevation command available. Configure `command` or install sudo (attempted `%s`)."):format(
        config.command()
      )
    )
    return false
  end

  if needs_prompt and not util.supports_stdin() then
    report_error(
      ("suda.nvim: command `%s` cannot prompt for a password. Enable `noninteractive = true` or use an executable that supports stdin prompts."):format(
        config.command()
      )
    )
    return false
  end

  return true
end

local function password_input()
  local password = util.get_password(config.options.prompt)
  if not password then
    util.notify("suda.nvim: password prompt cancelled", log.WARN)
    return nil
  end
  return password .. "\n"
end

local function format_failure(action, path, code, stderr)
  local err = util.trim(stderr)
  if err == "" then
    err = ("exit code %d"):format(code or -1)
  end
  return ("suda.nvim: failed to %s %s (%s)"):format(action, path, err)
end

---Read a file with elevated privileges.
---@param path string
---@return boolean success
function M.read(path)
  local needs_prompt = not config.options.noninteractive
  if not ensure_command(needs_prompt) then
    return false
  end

  local real_path = util.normalize_path(util.from_suda_path(path))
  if real_path == "" then
    report_error("suda.nvim: no path provided to read")
    return false
  end

  local cmd = util.get_sudo_cmd({
    noninteractive = config.options.noninteractive,
    prompt = config.options.prompt,
  })
  vim.list_extend(cmd, { "cat", "--", real_path })

  local input
  if needs_prompt then
    input = password_input()
    if not input then
      return false
    end
  end

  local lines, code, stderr = util.system(cmd, input)
  if code ~= 0 then
    report_error(format_failure("read", real_path, code, stderr))
    return false
  end

  local buf = vim.api.nvim_get_current_buf()
  vim.bo.modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo.modified = false
  vim.bo.readonly = false
  vim.bo.swapfile = false
  vim.bo.bufhidden = "hide"
  vim.bo.buftype = "acwrite"
  vim.b.suda_realpath = real_path

  return true
end

---Write a file with elevated privileges.
---@param path string
---@return boolean success
function M.write(path)
  local needs_prompt = not config.options.noninteractive
  if not ensure_command(needs_prompt) then
    return false
  end

  local real_path = util.normalize_path(util.from_suda_path(path))
  if real_path == "" then
    real_path = util.normalize_path(vim.b.suda_realpath or "")
  end
  if real_path == "" then
    report_error("suda.nvim: no target path to write")
    return false
  end

  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  local add_newline = not vim.bo.binary and vim.bo.eol and #lines > 0
  if add_newline then
    content = content .. "\n"
  end

  local cmd = util.get_sudo_cmd({
    noninteractive = config.options.noninteractive,
    prompt = config.options.prompt,
  })
  vim.list_extend(cmd, { "tee", "--", real_path })

  local input = content
  if needs_prompt then
    local password = password_input()
    if not password then
      return false
    end
    input = password .. content
  end

  local _, code, stderr = util.system(cmd, input, { text = false })
  if code ~= 0 then
    report_error(format_failure("write", real_path, code, stderr))
    vim.bo.modified = true
    return false
  end

  vim.bo.modified = false
  vim.b.suda_realpath = real_path
  if uv and uv.now then
    vim.b.suda_last_write = uv.now() / 1000
  else
    vim.b.suda_last_write = os.time()
  end

  util.notify(("suda.nvim: wrote %s with elevated permissions"):format(real_path), log.INFO)
  return true
end

---Setup autocmds for the suda:// protocol.
function M.setup_protocol()
  local group = vim.api.nvim_create_augroup("Suda", { clear = true })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = "suda://*",
    desc = "Read files through sudo",
    callback = function(event)
      if not M.read(event.match) then
        vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, {})
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    pattern = "suda://*",
    desc = "Write files through sudo",
    callback = function(event)
      if not M.write(event.match) then
        vim.bo.modified = true
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileReadCmd", {
    group = group,
    pattern = "suda://*",
    desc = "Handle :read for suda:// paths",
    callback = function(event)
      if not M.read(event.match) then
        vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, {})
      end
    end,
  })
end

---Setup smart edit feature.
function M.setup_smart_edit()
  local group = vim.api.nvim_create_augroup("SudaSmartEdit", { clear = true })

  if not config.options.smart_edit then
    return
  end

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPre" }, {
    group = group,
    desc = "Automatically reopen protected files using sudo",
    callback = function(event)
      local path = util.normalize_path(event.file or "")
      if path == "" or path:match("^suda://") then
        return
      end

      local exists = vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
      if exists and not util.is_readable(path) then
        vim.schedule(function()
          vim.cmd("edit " .. util.escape_path(util.to_suda_path(path)))
        end)
        return
      end

      local parent = vim.fn.fnamemodify(path, ":h")
      if parent ~= "" and not util.is_writable(parent) then
        vim.schedule(function()
          vim.cmd("edit " .. util.escape_path(util.to_suda_path(path)))
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    desc = "Warn before writing protected files without sudo",
    callback = function(event)
      local path = util.normalize_path(event.file or "")
      if path == "" or path:match("^suda://") then
        return
      end
      if util.is_writable(path) then
        return
      end
      util.notify(
        ("suda.nvim: %s is not writable. Use :SudaWrite to save with sudo."):format(path),
        log.WARN
      )
    end,
  })
end

return M
