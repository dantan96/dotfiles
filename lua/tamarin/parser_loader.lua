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
    
    -- Check for symbol naming inconsistency
    local cmd = string.format("nm -gU %s | grep tree_sitter", vim.fn.shellescape(parser_path))
    local handle = io.popen(cmd)
    if handle then
      local result = handle:read("*a")
      handle:close()
      log_to_file("Symbol check results: " .. result)
      
      if result:match("_tree_sitter_spthy") and not result:match("tree_sitter_tamarin") then
        log_to_file("✓ Found _tree_sitter_spthy symbol but not tree_sitter_tamarin")
      end
    end
    
    return true
  else
    log_to_file("✗ Parser file not found: " .. parser_path)
    return false
  end
end

-- Create a symlink to the parser with the correct name expected by neovim
local function create_parser_symlink(orig_parser_path, expected_name)
  local parser_dir = vim.fn.fnamemodify(orig_parser_path, ":h")
  local expected_path = parser_dir .. "/" .. expected_name .. ".so"
  
  log_to_file("Creating symlink from " .. orig_parser_path .. " to " .. expected_path)
  
  -- Remove existing symlink if it exists
  if vim.fn.filereadable(expected_path) == 1 then
    os.remove(expected_path)
    log_to_file("Removed existing file: " .. expected_path)
  end
  
  -- Create the symlink
  local success = vim.fn.system("ln -sf " .. vim.fn.shellescape(orig_parser_path) .. " " .. vim.fn.shellescape(expected_path))
  
  if success == "" then
    log_to_file("✓ Created symlink successfully")
    return true
  else
    log_to_file("✗ Failed to create symlink: " .. success)
    return false
  end
end

-- Direct language registration with vim.treesitter.language.register
local function register_language_directly(source_lang, target_filetype)
  log_to_file("Attempting direct language registration: " .. source_lang .. " for " .. target_filetype)
  
  if vim.treesitter and vim.treesitter.language and vim.treesitter.language.register then
    local ok, err = pcall(function()
      vim.treesitter.language.register(source_lang, target_filetype)
      return true
    end)
    
    if ok then
      log_to_file("✓ Successfully registered " .. source_lang .. " for " .. target_filetype .. " directly")
      return true
    else
      log_to_file("✗ Failed to register language directly: " .. tostring(err))
      return false
    end
  else
    log_to_file("✗ vim.treesitter.language.register not available")
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
  
  -- For tamarin, we need special handling
  if lang == "tamarin" then
    log_to_file("✓ Using special handling for tamarin parser")
    
    -- First try to use direct language registration from nvim 0.9+
    if register_language_directly("spthy", "tamarin") then
      -- We also need to load the parser
      -- Even though we've registered the language, we still need to add it
      local ok, result = pcall(function()
        return vim.treesitter.language.add("spthy", {path = parser_path})
      end)
      
      if ok and result then
        log_to_file("✓ Successfully added spthy language after registration")
        return true
      else
        log_to_file("✗ Failed to add spthy language after registration: " .. tostring(result))
      end
    end
    
    -- If direct registration fails, try adding the language as spthy
    local ok, result = pcall(function()
      return vim.treesitter.language.add("spthy", {path = parser_path})
    end)
    
    if ok and result then
      log_to_file("✓ Successfully added spthy language")
      
      -- Now register spthy for tamarin filetype
      if vim.treesitter.language.register then
        ok, result = pcall(function()
          vim.treesitter.language.register("spthy", "tamarin")
          return true
        end)
        
        if ok then
          log_to_file("✓ Successfully registered spthy for tamarin filetype")
          return true
        else
          log_to_file("✗ Failed to register spthy for tamarin: " .. tostring(result))
        end
      else
        log_to_file("✗ vim.treesitter.language.register not available, using legacy method")
        -- Legacy method: try to use nvim-treesitter's method
        if require("nvim-treesitter.parsers").get_parser_configs then
          local configs = require("nvim-treesitter.parsers").get_parser_configs()
          if configs and type(configs) == "table" then
            configs.tamarin = {
              install_info = {
                url = parser_path,
                files = {"parser.c"},
              },
              filetype = "tamarin",
              used_by = {"spthy", "sapic"},
            }
            log_to_file("✓ Added tamarin to nvim-treesitter parser configs")
            return true
          end
        end
      end
    else
      log_to_file("✗ Failed to add spthy language: " .. tostring(result))
    end
  else
    -- Normal processing for non-tamarin parsers
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
  
  return false
end

-- Register a language for a filetype
local function register_for_filetype(lang, ft)
  log_to_file("Registering language: " .. lang .. " for filetype: " .. ft)
  
  -- First try direct registration (Neovim 0.9+ preferred method)
  if register_language_directly(lang, ft) then
    return true
  end
  
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
  
  -- Try direct language registration first (Neovim 0.9+ preferred method)
  if register_language_directly("spthy", "tamarin") then
    result.spthy_registered = true
    
    -- After registration, we still need to add the parser
    local ok, res
    
    -- Try to add spthy parser
    if result.spthy_parser_found then
      ok, res = pcall(function() 
        return vim.treesitter.language.add("spthy", {path = spthy_parser_path})
      end)
      if ok and res then
        result.spthy_loaded = true
        result.tamarin_loaded = true
        log_to_file("✓ Successfully added spthy parser after registration")
      end
    end
    
    -- If that didn't work, try tamarin parser
    if not result.spthy_loaded and result.tamarin_parser_found then
      ok, res = pcall(function() 
        return vim.treesitter.language.add("spthy", {path = tamarin_parser_path})
      end)
      if ok and res then
        result.spthy_loaded = true
        result.tamarin_loaded = true
        log_to_file("✓ Successfully added tamarin parser as spthy after registration")
      end
    end
  else
    -- Fall back to traditional methods
    
    -- Create symlink to ensure parser is found with correct name
    if result.tamarin_parser_found and result.spthy_parser_found then
      -- Check if the parser has correct symbols
      local symlink_created = create_parser_symlink(tamarin_parser_path, "spthy")
      log_to_file("Symlink creation for tamarin parser: " .. tostring(symlink_created))
    end
    
    -- Try to load the tamarin parser (which has tree_sitter_spthy symbol)
    if result.tamarin_parser_found then
      result.tamarin_loaded = add_language('tamarin', tamarin_parser_path)
      log_to_file("Tamarin parser loading result: " .. tostring(result.tamarin_loaded))
    end
    
    -- If that didn't work, try with the spthy parser
    if not result.tamarin_loaded and result.spthy_parser_found then
      result.spthy_loaded = add_language('spthy', spthy_parser_path)
      log_to_file("Spthy parser loading result: " .. tostring(result.spthy_loaded))
      
      -- Register spthy for tamarin filetype
      if result.spthy_loaded then
        result.spthy_registered = register_for_filetype('spthy', 'tamarin')
        log_to_file("Spthy registration for tamarin result: " .. tostring(result.spthy_registered))
      end
    end
  end
  
  -- Check queries only if we have a parser registered
  if result.spthy_loaded or result.tamarin_loaded then
    result.spthy_query_ok = check_query('spthy', 'highlights')
    log_to_file("Spthy query check result: " .. tostring(result.spthy_query_ok))
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