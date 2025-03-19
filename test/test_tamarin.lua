-- Test script for Tamarin TreeSitter integration

-- Clean up any previous setup
local tamarin = require('tamarin')
tamarin.cleanup()

-- Setup Tamarin TreeSitter integration
print("Setting up Tamarin TreeSitter integration...")
local setup_ok = tamarin.setup()
print("Setup result: " .. (setup_ok and "SUCCESS" or "FAILED"))

-- Open the test file
vim.cmd("edit ~/tamarin-test/test.spthy")

-- Ensure filetype is set correctly
vim.cmd("set filetype=tamarin")

-- Ensure highlighting is set up
print("\nSetting up highlighting for current buffer...")
local highlight_ok = tamarin.ensure_highlighting(0)
print("Highlighting result: " .. (highlight_ok and "SUCCESS" or "FAILED"))

-- Test garbage collection
print("\nTesting garbage collection behavior...")
local gc_result = tamarin.test_gc(0)
print("GC prevention test: " .. (gc_result.active_after_gc and "PASSED" or "FAILED"))

-- Run diagnostics
print("\nRunning diagnostics...")
tamarin.diagnose()

print("\nTest completed. Check the highlighting in the open buffer.") 