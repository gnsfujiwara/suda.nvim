-- Basic tests for suda.nvim
-- Run with: nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

describe("suda.nvim", function()
  before_each(function()
    -- Reset module cache
    package.loaded["suda"] = nil
    package.loaded["suda.config"] = nil
    package.loaded["suda.util"] = nil
    package.loaded["suda.core"] = nil
  end)

  describe("setup", function()
    it("can be required", function()
      local suda = require("suda")
      assert.is_not_nil(suda)
    end)

    it("has setup function", function()
      local suda = require("suda")
      assert.is_function(suda.setup)
    end)

    it("accepts configuration options", function()
      local suda = require("suda")
      suda.setup({
        prompt = "Test: ",
        smart_edit = true,
      })
      
      local config = require("suda.config")
      assert.equals("Test: ", config.options.prompt)
      assert.is_true(config.options.smart_edit)
      assert.is_true(config.is_initialized())
    end)
  end)

  describe("util", function()
    local util

    before_each(function()
      util = require("suda.util")
    end)

    it("converts to suda path", function()
      assert.equals("suda:///etc/hosts", util.to_suda_path("/etc/hosts"))
    end)

    it("converts from suda path", function()
      assert.equals("/etc/hosts", util.from_suda_path("suda:///etc/hosts"))
    end)

    it("handles already suda paths", function()
      assert.equals("suda:///etc/hosts", util.to_suda_path("suda:///etc/hosts"))
    end)

    it("checks sudo availability", function()
      local has_sudo = util.has_sudo()
      assert.is_boolean(has_sudo)
      assert.is_boolean(util.supports_stdin())
    end)
  end)

  describe("config", function()
    local config

    before_each(function()
      config = require("suda.config")
    end)

    it("has default options", function()
      assert.is_not_nil(config.defaults)
      assert.equals("Password: ", config.defaults.prompt)
      assert.is_false(config.defaults.smart_edit)
      assert.is_false(config.defaults.noninteractive)
      assert.is_nil(config.defaults.command)
      assert.is_false(config.is_initialized())
    end)

    it("merges user options with defaults", function()
      config.setup({ prompt = "Custom: " })
      assert.equals("Custom: ", config.options.prompt)
      assert.is_false(config.options.smart_edit)
      assert.is_true(config.is_initialized())
    end)
  end)

  describe("commands", function()
    it("creates SudaRead command", function()
      require("suda").setup()
      local commands = vim.api.nvim_get_commands({})
      assert.is_not_nil(commands.SudaRead)
    end)

    it("creates SudaWrite command", function()
      require("suda").setup()
      local commands = vim.api.nvim_get_commands({})
      assert.is_not_nil(commands.SudaWrite)
    end)
  end)
end)
