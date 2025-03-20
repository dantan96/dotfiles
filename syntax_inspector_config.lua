-- Configuration file for the Syntax Inspector
-- Used with the SyntaxInspect command

return {
  -- File to analyze
  file_path = "test.spthy",
  
  -- Output paths
  output_report = "syntax_report.md",
  output_html = "syntax_visualization.html",
  
  -- Patterns to match
  patterns = {
    -- Keywords
    "function", "rule", "lemma", "let", "in", "protocol", "builtins", "restriction",
    
    -- Facts and terms
    "F%([^)]*%)", "Fr%([^)]*%)", "Out%([^)]*%)",
    
    -- Operators
    "~>", "==", "==>", "-->", "-->%*",
    
    -- Literals
    "'%w+'", "\"[^\"]*\"", 
    
    -- Comments
    "//[^\n]*", "/%*.*%*/"
  },
  
  -- Expected highlight groups
  expected_highlights = {
    -- Keywords
    ["function"] = "Function",
    ["rule"] = "Keyword", 
    ["let"] = "Keyword",
    ["in"] = "Keyword",
    
    -- Facts and terms
    ["F"] = "SpthyFact",
    ["Fr"] = "SpthyFresh",
    ["Out"] = "SpthyMessage",
    
    -- Operators
    ["~>"] = "SpthyOperator",
    ["=="] = "SpthyOperator",
    ["==>"] = "SpthyArrow",
    ["-->"] = "SpthyArrow",
    ["-->%*"] = "SpthyArrow",
    
    -- Literals
    ["'"] = "SpthyApostrophe",
    ["\""] = "String",
    
    -- Comments
    ["//"] = "Comment",
    ["/%*"] = "Comment",
    
    -- Sections
    ["protocol"] = "SpthySection",
    ["builtins"] = "SpthySection",
    
    -- Special keywords
    ["rule"] = "SpthyRule",
    ["lemma"] = "SpthyLemma",
    ["restriction"] = "SpthyRestriction",
    
    -- Default fallback
    ["_default"] = "Normal"
  }
} 