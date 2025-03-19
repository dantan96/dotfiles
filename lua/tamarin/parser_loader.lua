-- Tamarin Parser Loader
-- Robust module for loading and registering Tamarin/Spthy TreeSitter parsers

local M = {}

-- Debug flag - set to true for detailed logging
local DEBUG = true

-- Helper function to log messages when debug is enabled
local function log(msg, level)
  if DEBUG then
    local log_level = level or vim.log.levels.INFO
    vim.notify("[tamarin-parser] " .. msg, log_level)
  end
end

-- Create a temporary log file for debugging
local function log_to_file(msg)
  if DEBUG then
    local log_dir = "/tmp/tamarin-debug"
    vim.fn.mkdir(log_dir, "p")
    local log_file = log_dir .. "/parser_loader.log"
    local file = io.open(log_file, "a")
    if file then
      file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
      file:close()
    end
  end
end

-- Check parser path and log results
local function check_parser(parser_path, name)
  log_to_file("Checking parser: " .. name .. " at " .. parser_path)
  
  if vim.fn.filereadable(parser_path) == 1 then
    log_to_file("✓ Parser file exists: " .. parser_path)
    return true
  else
    log_to_file("✗ Parser file not found: " .. parser_path)
    return false
  end
end

-- Safely add a parser language
local function add_language(lang, parser_path)
  log_to_file("Attempting to add language: " .. lang .. " with parser: " .. parser_path)
  
  -- Check if the function exists
  if not vim.treesitter.language.add then
    log_to_file("✗ vim.treesitter.language.add not available")
    return false
  end
  
  -- Try to add the language
  local ok, result = pcall(function()
    return vim.treesitter.language.add(lang, {path = parser_path})
  end)
  
  if ok and result then
    log_to_file("✓ Successfully added language: " .. lang)
    return true
  else
    log_to_file("✗ Failed to add language: " .. lang .. " - " .. tostring(result))
    return false
  end
end

-- Register a language for a filetype
local function register_for_filetype(lang, ft)
  log_to_file("Registering language: " .. lang .. " for filetype: " .. ft)
  
  -- Check if the function exists
  if not vim.treesitter.language.register then
    log_to_file("✗ vim.treesitter.language.register not available")
    return false
  end
  
  -- Try to register the language
  local ok, result = pcall(function()
    vim.treesitter.language.register(lang, ft)
    return true
  end)
  
  if ok then
    log_to_file("✓ Successfully registered " .. lang .. " for filetype: " .. ft)
    return true
  else
    log_to_file("✗ Failed to register for filetype: " .. tostring(result))
    return false
  end
end

-- Check query file existence and validity
local function check_query(lang, query_type)
  local query_files = vim.api.nvim_get_runtime_file("queries/" .. lang .. "/" .. query_type .. ".scm", true)
  
  if #query_files > 0 then
    log_to_file("✓ Found " .. query_type .. " query for " .. lang .. ": " .. query_files[1])
    
    -- Try parsing the query
    local content = io.open(query_files[1]):read("*all")
    local ok, err = pcall(function()
      return vim.treesitter.query.parse(lang, content)
    end)
    
    if ok then
      log_to_file("✓ Query parsed successfully")
      return true
    else
      log_to_file("✗ Error parsing query: " .. tostring(err))
      return false
    end
  else
    log_to_file("✗ No " .. query_type .. " query found for " .. lang)
    return false
  end
end

-- Main function to ensure parsers are properly loaded
function M.ensure_parsers_loaded()
  log("Starting parser loader", vim.log.levels.INFO)
  log_to_file("=== Starting parser loader ===")
  
  -- Initialize results
  local result = {
    spthy_parser_found = false,
    tamarin_parser_found = false,
    spthy_loaded = false,
    tamarin_loaded = false,
    spthy_registered = false,
    spthy_query_ok = false
  }
  
  -- Check all possible parser locations
  local config_dir = vim.fn.stdpath('config')
  local spthy_parser_path = config_dir .. "/parser/spthy/spthy.so"
  local tamarin_parser_path = config_dir .. "/parser/tamarin/tamarin.so"
  
  -- Check if parsers exist
  result.spthy_parser_found = check_parser(spthy_parser_path, "spthy")
  result.tamarin_parser_found = check_parser(tamarin_parser_path, "tamarin")
  
  -- Try to load spthy parser first
  if result.spthy_parser_found then
    result.spthy_loaded = add_language('spthy', spthy_parser_path)
  end
  
  -- Register spthy for tamarin filetype
  if result.spthy_loaded then
    result.spthy_registered = register_for_filetype('spthy', 'tamarin')
  end
  
  -- Check queries
  if result.spthy_loaded then
    result.spthy_query_ok = check_query('spthy', 'highlights')
  end
  
  -- If spthy failed, try tamarin parser as fallback
  if not result.spthy_loaded and result.tamarin_parser_found then
    result.tamarin_loaded = add_language('tamarin', tamarin_parser_path)
  end
  
  -- Log final results
  log_to_file("=== Parser loading results ===")
  for k, v in pairs(result) do
    log_to_file(k .. ": " .. tostring(v))
  end
  
  return result
end

-- Attempt to start TreeSitter highlighting for a buffer
function M.start_highlighting(bufnr)
  bufnr = bufnr or 0
  
  log_to_file("Attempting to start highlighting for buffer: " .. bufnr)
  
  -- Get filetype
  local ft = vim.bo[bufnr].filetype
  log_to_file("Buffer filetype: " .. ft)
  
  -- Get language for this filetype
  local lang = nil
  if vim.treesitter.language.get_lang then
    lang = vim.treesitter.language.get_lang(ft)
  end
  
  if lang then
    log_to_file("Found language for filetype: " .. lang)
    
    -- Try to start the parser
    local ok, err = pcall(function()
      return vim.treesitter.start(bufnr, lang)
    end)
    
    if ok then
      log_to_file("✓ Successfully started TreeSitter for buffer")
      return true
    else
      log_to_file("✗ Failed to start TreeSitter: " .. tostring(err))
      return false
    end
  else
    log_to_file("✗ No language found for filetype: " .. ft)
    return false
  end
end

return M 