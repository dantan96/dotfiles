-- Verification script for Tamarin syntax highlighting

local M = {}

local log_file = io.open(vim.fn.expand("~/.cache/nvim/tamarin_verification.log"), "w")

local function log(msg)
  log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
  log_file:flush()
  print(msg)
end

-- Test if the Tamarin module is available
function M.test_module_availability()
  log("Testing Tamarin module availability...")
  
  local tamarin_ok, tamarin = pcall(require, "tamarin")
  if not tamarin_ok then
    log("FAIL: Tamarin module not available")
    return false
  end
  
  log("SUCCESS: Tamarin module loaded")
  return true
end

-- Test if TreeSitter is available
function M.test_treesitter_availability()
  log("Testing TreeSitter availability...")
  
  if not vim.treesitter then
    log("FAIL: TreeSitter not available")
    return false
  end
  
  log("SUCCESS: TreeSitter available")
  return true
end

-- Test parser registration
function M.test_parser_registration()
  log("Testing parser registration...")
  
  local tamarin = require("tamarin")
  local parser = require("tamarin.parser")
  
  -- Clean up previous setup
  tamarin.cleanup()
  
  -- Register parser
  local register_ok = parser.register_parser()
  if not register_ok then
    log("FAIL: Parser registration failed")
    return false
  end
  
  -- Try to get a parser for a test buffer
  local parser_ok, _ = pcall(vim.treesitter.get_parser, 0, 'spthy')
  if not parser_ok then
    log("FAIL: Could not get parser after registration")
    return false
  end
  
  log("SUCCESS: Parser registered and functional")
  return true
end

-- Test highlighting setup
function M.test_highlighting_setup()
  log("Testing highlighting setup...")
  
  local tamarin = require("tamarin")
  local highlighter = require("tamarin.highlighter")
  
  -- Open test file
  vim.cmd("edit " .. vim.fn.stdpath("config") .. "/test/verification/test_tamarin.spthy")
  
  -- Ensure filetype is set
  vim.cmd("set filetype=tamarin")
  
  -- Set up highlighting
  local highlight_ok = highlighter.setup_highlighting(0)
  if not highlight_ok then
    log("FAIL: Highlighting setup failed")
    return false
  end
  
  -- Check if highlighter is active
  local is_active = highlighter.has_active_highlighter(0)
  if not is_active then
    log("FAIL: Highlighter not active after setup")
    return false
  end
  
  log("SUCCESS: Highlighting set up and active")
  return true
end

-- Test garbage collection prevention
function M.test_gc_prevention()
  log("Testing garbage collection prevention...")
  
  local highlighter = require("tamarin.highlighter")
  
  -- Check if highlighter is active before GC
  local active_before = highlighter.has_active_highlighter(0)
  if not active_before then
    log("FAIL: Highlighter not active before GC test")
    return false
  end
  
  -- Force garbage collection
  collectgarbage("collect")
  collectgarbage("collect")
  
  -- Check if highlighter is still active
  local active_after = highlighter.has_active_highlighter(0)
  if not active_after then
    log("FAIL: Highlighter lost after garbage collection")
    return false
  end
  
  log("SUCCESS: Highlighter preserved through garbage collection")
  return true
end

-- Run all verification tests
function M.run_verification()
  log("Starting Tamarin syntax highlighting verification...")
  
  local results = {
    module_availability = M.test_module_availability(),
    treesitter_availability = M.test_treesitter_availability(),
    parser_registration = M.test_parser_registration(),
    highlighting_setup = M.test_highlighting_setup(),
    gc_prevention = M.test_gc_prevention()
  }
  
  -- Print summary
  log("\nVerification Summary:")
  for test, result in pairs(results) do
    log("  " .. test .. ": " .. (result and "PASS" or "FAIL"))
  end
  
  -- Overall result
  local overall = true
  for _, result in pairs(results) do
    if not result then
      overall = false
      break
    end
  end
  
  log("\nOverall result: " .. (overall and "PASS" or "FAIL"))
  log("Log file written to: " .. vim.fn.expand("~/.cache/nvim/tamarin_verification.log"))
  
  log_file:close()
  return overall
end

return M 