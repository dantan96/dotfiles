-- Tamarin Syntax Highlighting Diagnostic Tool
-- Analyzes syntax highlighting for Tamarin .spthy files

local M = {}

-- Create a temporary spthy file with all syntax elements to test
local function create_test_file()
  local test_file = vim.fn.stdpath("cache") .. "/tamarin_test.spthy"
  local content = [[
// TAMARIN SYNTAX TEST FILE
/* Multiline comment
   with multiple lines */

theory TestTheory
begin

builtins: diffie-hellman, signing, hashing

// FACTS: Persistent vs Linear vs Action
rule TestFactTypes:
  [ Fr(~k) ]
  --[ TestAction($A, ~k, #i), TestAction2(!LTK, 'constant') ]->
  [ !PersistentFact($A, ~k),
    LinearFact(~k),
    Out(<$A, ~k, #i>) ]

// VARIABLES: Public, Fresh, Temporal, Message
rule TestVariableTypes:
  [ In($PublicVar),
    Fr(~freshVar),
    LinearFact(x:msg) ]
  --[ At(#time) ]->
  [ Out(<$PublicVar, ~freshVar, #time>) ]

// FUNCTIONS: Normal and Builtin
rule TestFunctions:
  [ Fr(~k) ]
  -->
  [ Out(h(~k)), 
    Out(pk(~k)),
    Out(sign(~k, 'message')),
    Out(verify(sign(~k, 'message'), pk(~k), 'message')) ]

// KEYWORDS and RULE STRUCTURE
lemma test_lemma:
  "All #i. Test() @i ==> Ex #j. Response() @j"

axiom test_axiom:
  "All x #i. Some_Action(x) @i ==> x = 'valid'"

restriction test_restriction:
  "All A B #i. Neq(A, B) @ i ==> not(A = B)"

// ACTION FACTS in different constructs
rule ActionFactTest:
  let pubval = 'something' in
  [ Fr(~k), !KeyStore(~k) ]
  --[ SomeAction('constant'),
      OtherAction($X, ~k, #t) ]->
  [ Out(~k) ]

end
]]
  vim.fn.writefile(vim.split(content, "\n"), test_file)
  return test_file
end

-- Direct syntax inspection without requiring highlight_inspector
function M.direct_diagnostic()
  -- Create test file
  local test_file = create_test_file()
  local output_file = vim.fn.stdpath("cache") .. "/tamarin_highlight_report.md"
  
  -- List of test cases to check
  local test_cases = {
    { description = "Comments", patterns = { "//[^\n]*", "/%*.*%*/" } },
    { description = "Keywords", patterns = { "theory", "begin", "end", "rule", "lemma", "axiom" } },
    { description = "Public Variables", patterns = { "$[A-Za-z0-9_]+" } },
    { description = "Fresh Variables", patterns = { "~[A-Za-z0-9_]+" } },
    { description = "Temporal Variables", patterns = { "#[A-Za-z0-9_]+" } },
    { description = "Persistent Facts", patterns = { "![A-Z][A-Za-z0-9_]*" } },
    { description = "Linear Facts", patterns = { "LinearFact", "TestAction" } },
    { description = "Builtin Facts", patterns = { "Fr", "In", "Out" } },
    { description = "Functions", patterns = { "h", "pk", "sign", "verify" } },
    { description = "Action Blocks", patterns = { "--[", "]->" } }
  }
  
  -- Function to execute diagnostic in a headless nvim instance
  local function execute_diagnostic()
    -- Open the test file
    vim.cmd("edit " .. vim.fn.fnameescape(test_file))
    vim.cmd("set filetype=spthy")
    
    -- Enable syntax highlighting
    vim.cmd("syntax on")
    vim.cmd("redraw")
    
    -- Results storage
    local results = {
      "# Tamarin Syntax Highlighting Diagnostic Report\n",
      "Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n",
      "## Test Cases\n\n"
    }
    
    -- Check each test case
    for _, case in ipairs(test_cases) do
      table.insert(results, "### " .. case.description .. "\n\n")
      table.insert(results, "| Line | Text | Highlight Group | Expected Group | Status |\n")
      table.insert(results, "|------|------|----------------|----------------|--------|\n")
      
      local found = false
      
      -- Check content line by line for matches
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for line_num, line_text in ipairs(lines) do
        for _, pattern in ipairs(case.patterns) do
          local start_col = string.find(line_text, pattern)
          if start_col then
            found = true
            local matched_text = string.match(line_text, pattern)
            
            -- Get syntax ID at position
            local syntax_id = vim.fn.synID(line_num, start_col, true)
            local syntax_name = vim.fn.synIDattr(syntax_id, "name")
            local trans_id = vim.fn.synIDtrans(syntax_id)
            local trans_name = vim.fn.synIDattr(trans_id, "name")
            
            -- Get color
            local fg_color = vim.fn.synIDattr(trans_id, "fg#")
            
            -- Determine expected group based on case
            local expected_group = ""
            if case.description == "Comments" then
              expected_group = "spthyComment"
            elseif case.description == "Keywords" then
              expected_group = "spthyKeyword"
            elseif case.description == "Public Variables" then
              expected_group = "spthyPublicVar"
            elseif case.description == "Fresh Variables" then
              expected_group = "spthyFreshVar"
            elseif case.description == "Temporal Variables" then
              expected_group = "spthyTemporalVar"
            elseif case.description == "Persistent Facts" then
              expected_group = "spthyPersistentFact"
            elseif case.description == "Linear Facts" then
              expected_group = "spthyNormalFact"
            elseif case.description == "Builtin Facts" then
              expected_group = "spthyBuiltinFact"
            elseif case.description == "Functions" then
              expected_group = "spthyFunction"
            elseif case.description == "Action Blocks" then
              expected_group = "spthyRuleArrow"
            end
            
            -- Check status
            local status = trans_name == expected_group and "✅ Match" or "❌ Mismatch"
            
            -- Format for output
            local result_line = string.format(
              "| %d | `%s` | %s | %s | %s |\n", 
              line_num, 
              matched_text:gsub("|", "\\|"):sub(1, 20), 
              trans_name .. " (fg: " .. (fg_color or "default") .. ")", 
              expected_group,
              status
            )
            
            table.insert(results, result_line)
          end
        end
      end
      
      if not found then
        table.insert(results, "| | No matches found | | | |\n")
      end
      
      table.insert(results, "\n")
    end
    
    -- Write results to file
    vim.fn.writefile(results, output_file)
    
    -- Cleanup
    vim.cmd("qa!")
  end
  
  -- Run diagnostic in a separate Neovim instance
  local tmpfile = vim.fn.tempname() .. ".lua"
  local script = [[
  vim.opt.termguicolors = true
  vim.opt.runtimepath:append("]] .. vim.fn.stdpath("config") .. [[")
  require('config.tamarin-colors').setup()
  vim.schedule(function() ]] .. string.dump(execute_diagnostic):gsub("\n", " ") .. [[ end)
  ]]
  
  vim.fn.writefile({script}, tmpfile)
  os.execute("nvim --headless -l " .. tmpfile)
  os.remove(tmpfile)
  
  -- Inform user
  print("\nDiagnostic complete!")
  print("Results saved to: " .. output_file)
  
  return output_file
end

-- Create a command to run the diagnostic
function M.setup()
  vim.api.nvim_create_user_command("TamarinDiagnostic", function()
    local output_file = M.direct_diagnostic()
    vim.cmd("edit " .. output_file)
  end, {
    desc = "Run a diagnostic on Tamarin syntax highlighting"
  })
end

return M 