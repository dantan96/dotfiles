-- setup_tests.lua
-- Set up Tamarin syntax highlighting test environment

local M = {}

-- Configuration
local config = {
  output_dir = vim.fn.expand("~/temp_files"),
  test_dir = vim.fn.stdpath('config') .. '/test/tamarin',
  debug = true
}

-- Set up logging
local function log(msg, level)
  level = level or vim.log.levels.INFO
  if config.debug then
    vim.notify("[TestSetup] " .. msg, level)
  end
end

-- Check if test environment is set up
local function is_test_env_ready()
  -- Check if test directory exists
  if vim.fn.isdirectory(config.test_dir) ~= 1 then
    log("Test directory does not exist: " .. config.test_dir, vim.log.levels.WARN)
    return false
  end
  
  -- Check if test file exists
  local test_file = config.test_dir .. "/test.spthy"
  if vim.fn.filereadable(test_file) ~= 1 then
    log("Test file does not exist: " .. test_file, vim.log.levels.WARN)
    return false
  end
  
  -- Check if output directory exists
  if vim.fn.isdirectory(config.output_dir) ~= 1 then
    log("Output directory does not exist: " .. config.output_dir, vim.log.levels.WARN)
    return false
  end
  
  return true
end

-- Create necessary directories
local function setup_directories()
  -- Create test directory
  if vim.fn.isdirectory(config.test_dir) ~= 1 then
    vim.fn.mkdir(config.test_dir, "p")
    log("Created test directory: " .. config.test_dir)
  end
  
  -- Create output directory
  if vim.fn.isdirectory(config.output_dir) ~= 1 then
    vim.fn.mkdir(config.output_dir, "p")
    log("Created output directory: " .. config.output_dir)
  end
  
  return true
end

-- Copy test file if it doesn't exist
local function setup_test_file()
  local test_file = config.test_dir .. "/test.spthy"
  
  if vim.fn.filereadable(test_file) ~= 1 then
    -- Create a basic test file
    local content = [[
/*
 * Test file for validating Tamarin syntax highlighting
 * This file contains various Tamarin Protocol Prover language constructs
 */

theory TestHighlighting
begin

builtins: diffie-hellman, hashing, symmetric-encryption, signing

/* Types and function declarations */
functions: f/1, g/2, test/3
equations: f(g(x,y)) = h(<x,y>)

/* Security properties */
lemma secrecy_of_key [reuse]:
  "All A B k #i.
    Secret(k, A, B)@i ==>
    not (Ex #j. K(k)@j)
    | (Ex X #r. Reveal(X)@r & Honest(X)@i)"

/* Rule block with annotations, facts and terms */
rule Register_User:
  [ Fr(~id), Fr(~ltk) ]
  --[ OnlyOnce(), Create($A, ~id), LongTermKey($A, ~ltk) ]->
  [ !User($A, ~id, ~ltk), !Pk($A, pk(~ltk)), Out(pk(~ltk)) ]

end
]]
    
    local ok = vim.fn.writefile(vim.split(content, "\n"), test_file)
    if ok == 0 then
      log("Created test file: " .. test_file)
      return true
    else
      log("Failed to create test file: " .. test_file, vim.log.levels.ERROR)
      return false
    end
  end
  
  return true
end

-- Set up the test environment
function M.setup()
  log("Setting up test environment...")
  
  -- Check if already set up
  if is_test_env_ready() then
    log("Test environment is already set up")
    return true
  end
  
  -- Set up directories
  if not setup_directories() then
    log("Failed to set up directories", vim.log.levels.ERROR)
    return false
  end
  
  -- Set up test file
  if not setup_test_file() then
    log("Failed to set up test file", vim.log.levels.ERROR)
    return false
  end
  
  log("Test environment set up successfully")
  return true
end

-- Create Neovim commands for running tests
function M.create_commands()
  log("Creating test commands...")
  
  -- First make sure environment is set up
  if not M.setup() then
    log("Cannot create commands - test environment setup failed", vim.log.levels.ERROR)
    return false
  end
  
  -- Create commands
  vim.cmd([[
    command! -nargs=0 TamarinTestSetup lua require('test.setup_tests').setup()
    command! -nargs=0 TamarinTestAll lua require('test.run_tests').run_all_tests()
    command! -nargs=0 TamarinTestInteractive lua require('test.run_tests').run_interactive()
    command! -nargs=0 TamarinTestPlayground lua require('test.treesitter_playground').open()
  ]])
  
  log("Commands created")
  return true
end

-- Initialize everything
function M.init()
  -- Set up environment
  M.setup()
  
  -- Create commands
  M.create_commands()
  
  -- Initialize test modules
  pcall(function() require('test.run_tests').setup_commands() end)
  
  log("Test system initialized")
  return true
end

return M 