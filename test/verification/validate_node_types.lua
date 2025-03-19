-- Tamarin TreeSitter Node Type Validation Script
-- This script validates the node types used in the highlights.scm file
-- against the actual node types exported by the Tamarin/Spthy TreeSitter grammar

local M = {}

-- Function to extract all node types from a file
local function extract_node_types(file_path)
    -- Create a temporary buffer with some Tamarin code
    local bufnr = vim.api.nvim_create_buf(false, true)
    local contents = {}
    
    -- Read file contents if provided
    if file_path then
        local f = io.open(file_path, "r")
        if f then
            local content = f:read("*all")
            f:close()
            contents = vim.split(content, "\n")
        else
            contents = {
                "theory Test",
                "begin",
                "rule Test:",
                "  [ ] --[ ]-> [ ]",
                "lemma test:",
                "  exists-trace",
                "  \"Test lemma\"",
                "end"
            }
        end
    else
        contents = {
            "theory Test",
            "begin",
            "rule Test:",
            "  [ ] --[ ]-> [ ]",
            "lemma test:",
            "  exists-trace",
            "  \"Test lemma\"",
            "end"
        }
    end
    
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.api.nvim_buf_set_option(bufnr, "filetype", "tamarin")
    
    -- Register the language mapping (this is crucial for the parser to work)
    if vim.treesitter.language and vim.treesitter.language.register then
        pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
    end
    
    -- Parse the buffer with a pcall to handle errors
    local success, parser = pcall(vim.treesitter.get_parser, bufnr, "spthy")
    
    if not success or not parser then
        print("Error creating parser: " .. tostring(parser))
        vim.api.nvim_buf_delete(bufnr, { force = true })
        return {}
    end
    
    -- Get the syntax tree with pcall to handle errors
    local tree_success, tree = pcall(function() return parser:parse()[1] end)
    if not tree_success or not tree then
        print("Error parsing tree: " .. tostring(tree))
        vim.api.nvim_buf_delete(bufnr, { force = true })
        return {}
    end
    
    local root = tree:root()
    if not root then
        print("Error: Root node is nil")
        vim.api.nvim_buf_delete(bufnr, { force = true })
        return {}
    end
    
    -- Set to collect all node types
    local node_types = {}
    
    -- Recursive function to visit all nodes
    local function visit_node(node)
        local node_type = node:type()
        node_types[node_type] = true
        
        -- Visit child nodes
        for child, _ in node:iter_children() do
            visit_node(child)
        end
    end
    
    -- Start visiting from the root with pcall to handle errors
    local visit_success, err = pcall(function() visit_node(root) end)
    if not visit_success then
        print("Error visiting nodes: " .. tostring(err))
    end
    
    -- Clean up the buffer
    vim.api.nvim_buf_delete(bufnr, { force = true })
    
    return node_types
end

-- Function to extract node types from highlights.scm
local function extract_query_node_types(query_file)
    local node_types = {}
    local pattern = "%(([%w_]+)%)"  -- Match (node_type)
    
    local f = io.open(query_file, "r")
    if not f then
        print("Error: Could not open query file: " .. query_file)
        return {}
    end
    
    local content = f:read("*all")
    f:close()
    
    -- Extract all node types from the query file
    for node_type in content:gmatch(pattern) do
        if not node_type:match("^@") and node_type ~= "_" then
            node_types[node_type] = true
        end
    end
    
    return node_types
end

-- Function to validate a highlights.scm file against the parser
function M.validate_highlights_scm(query_file, output_file)
    print("Starting highlights.scm validation...")
    
    -- Get actual node types from parser
    local parser_node_types = extract_node_types()
    
    -- Get node types from highlights.scm
    local query_node_types = extract_query_node_types(query_file)
    
    -- Check if all query node types exist in the parser
    local invalid_node_types = {}
    for node_type, _ in pairs(query_node_types) do
        if not parser_node_types[node_type] then
            table.insert(invalid_node_types, node_type)
        end
    end
    
    -- Output results
    local f = io.open(output_file, "w")
    if not f then
        print("Error: Could not create output file: " .. output_file)
        return false
    end
    
    f:write("# Tamarin TreeSitter Node Type Validation\n\n")
    
    if #invalid_node_types > 0 then
        f:write("## ❌ Invalid Node Types\n\n")
        f:write("The following node types in `highlights.scm` do not exist in the parser:\n\n")
        for _, node_type in ipairs(invalid_node_types) do
            f:write("- `" .. node_type .. "`\n")
        end
        f:write("\n")
    else
        f:write("## ✅ All Node Types Valid\n\n")
        f:write("All node types in `highlights.scm` exist in the parser.\n\n")
    end
    
    f:write("## 📋 Available Node Types\n\n")
    f:write("The following node types are available in the parser:\n\n")
    local available_node_types = {}
    for node_type, _ in pairs(parser_node_types) do
        table.insert(available_node_types, node_type)
    end
    table.sort(available_node_types)
    for _, node_type in ipairs(available_node_types) do
        f:write("- `" .. node_type .. "`\n")
    end
    
    f:close()
    
    print("Validation complete. Results saved to: " .. output_file)
    
    -- Return true if all node types are valid
    return #invalid_node_types == 0
end

-- Main function to run the validation
function M.run_validation()
    -- Set a vim timeout to ensure we don't hang
    vim.defer_fn(function()
        print("Validation timed out after 3 seconds, forcing exit")
        vim.cmd('qa!')
    end, 3000)  -- 3 second timeout

    print("Starting node type validation for Tamarin/Spthy...")
    
    -- Register the language mapping (this is crucial for the parser to work)
    if vim.treesitter.language and vim.treesitter.language.register then
        local reg_success = pcall(vim.treesitter.language.register, 'spthy', 'tamarin')
        if not reg_success then
            print("Failed to register language mapping")
        end
    end
    
    -- Set log file path
    local log_file = vim.fn.stdpath("cache") .. "/tamarin_node_types.log"
    
    -- Validate the highlights.scm file with pcall to handle errors
    local query_file = vim.fn.stdpath("config") .. "/queries/spthy/highlights.scm"
    local success, result = pcall(M.validate_highlights_scm, query_file, log_file)
    
    if not success then
        print("Error during validation: " .. tostring(result))
        -- Write to log file even if there was an error
        local f = io.open(log_file, "w")
        if f then
            f:write("# Tamarin TreeSitter Node Type Validation\n\n")
            f:write("## ❌ Error During Validation\n\n")
            f:write("An error occurred during validation: " .. tostring(result) .. "\n")
            f:close()
        end
        
        -- Make sure to exit
        vim.defer_fn(function() vim.cmd('qa!') end, 100)
        return false
    end
    
    if result then
        print("✅ All node types in highlights.scm are valid. See " .. log_file .. " for details.")
        -- Make sure to exit
        vim.defer_fn(function() vim.cmd('qa!') end, 100)
        return true
    else
        print("❌ Invalid node types found in highlights.scm. See " .. log_file .. " for details.")
        -- Make sure to exit
        vim.defer_fn(function() vim.cmd('qa!') end, 100)
        return false
    end
end

return M 