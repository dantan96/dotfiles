-- Test highlights.scm for potential regex pattern issues
-- This script analyzes a TreeSitter highlights.scm file to identify regex patterns
-- that might cause stack overflow errors

local function log(msg)
  print("[highlight_test] " .. msg)
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

local function extract_match_patterns(content)
  local patterns = {}
  
  -- Find all #match? patterns
  for capture, pattern in content:gmatch("%(#match%? @([%w_%.]+) \"(.-)\"%)") do
    table.insert(patterns, {
      type = "match",
      capture = capture,
      pattern = pattern,
      source = string.format("(#match? @%s \"%s\")", capture, pattern)
    })
  end
  
  return patterns
end

local function test_vim_regex(pattern)
  local success, err = pcall(function()
    vim.regex(pattern)
  end)
  
  return success, err
end

local function analyze_pattern(pattern)
  local analysis = {
    pattern = pattern.pattern,
    risk_factors = {},
    risk_level = "low"
  }
  
  -- Check for nested quantifiers like (a+)+
  if pattern.pattern:match("%(.-[%+%*%?].-%)%s*[%+%*%?]") then
    table.insert(analysis.risk_factors, "Contains nested quantifiers")
    analysis.risk_level = "high"
  end
  
  -- Check for excessive alternation like (a|b|c|d|e)
  local alt_count = 0
  for _ in pattern.pattern:gmatch("|") do
    alt_count = alt_count + 1
  end
  
  if alt_count > 3 then
    table.insert(analysis.risk_factors, "Contains excessive alternation (" .. alt_count .. " alternates)")
    analysis.risk_level = "medium"
  end
  
  -- Check for backreferences
  if pattern.pattern:match("\\%d") then
    table.insert(analysis.risk_factors, "Contains backreferences")
    analysis.risk_level = "high"
  end
  
  -- Check for case-insensitive workarounds like [aA][bB][cC]
  local case_insensitive_chars = 0
  for _ in pattern.pattern:gmatch("%[%a%A%]") do
    case_insensitive_chars = case_insensitive_chars + 1
  end
  
  if case_insensitive_chars > 3 then
    table.insert(analysis.risk_factors, "Contains case-insensitive character classes")
    if analysis.risk_level ~= "high" then
      analysis.risk_level = "medium"
    end
  end
  
  -- Test compilation with Vim's regex engine
  local success, err = test_vim_regex(pattern.pattern)
  if not success then
    table.insert(analysis.risk_factors, "Failed to compile: " .. err)
    analysis.risk_level = "critical"
  end
  
  if #analysis.risk_factors == 0 then
    table.insert(analysis.risk_factors, "No risk factors identified")
  end
  
  return analysis
end

local function generate_report(file_path, patterns, analyses)
  local output = "# TreeSitter Highlights Analysis Report\n\n"
  
  output = output .. "## File Analyzed\n\n"
  output = output .. "- " .. file_path .. "\n\n"
  
  output = output .. "## Summary\n\n"
  output = output .. "- Total regex patterns: " .. #patterns .. "\n"
  
  local risk_counts = {
    critical = 0,
    high = 0,
    medium = 0,
    low = 0
  }
  
  for _, analysis in ipairs(analyses) do
    risk_counts[analysis.risk_level] = risk_counts[analysis.risk_level] + 1
  end
  
  output = output .. "- Critical risk patterns: " .. risk_counts.critical .. "\n"
  output = output .. "- High risk patterns: " .. risk_counts.high .. "\n"
  output = output .. "- Medium risk patterns: " .. risk_counts.medium .. "\n"
  output = output .. "- Low risk patterns: " .. risk_counts.low .. "\n\n"
  
  -- List patterns by risk level
  if risk_counts.critical > 0 then
    output = output .. "## Critical Risk Patterns\n\n"
    for _, analysis in ipairs(analyses) do
      if analysis.risk_level == "critical" then
        output = output .. "### Pattern: `" .. analysis.pattern .. "`\n\n"
        output = output .. "Risk factors:\n"
        for _, factor in ipairs(analysis.risk_factors) do
          output = output .. "- " .. factor .. "\n"
        end
        output = output .. "\n"
      end
    end
  end
  
  if risk_counts.high > 0 then
    output = output .. "## High Risk Patterns\n\n"
    for _, analysis in ipairs(analyses) do
      if analysis.risk_level == "high" then
        output = output .. "### Pattern: `" .. analysis.pattern .. "`\n\n"
        output = output .. "Risk factors:\n"
        for _, factor in ipairs(analysis.risk_factors) do
          output = output .. "- " .. factor .. "\n"
        end
        output = output .. "\n"
      end
    end
  end
  
  if risk_counts.medium > 0 then
    output = output .. "## Medium Risk Patterns\n\n"
    for _, analysis in ipairs(analyses) do
      if analysis.risk_level == "medium" then
        output = output .. "### Pattern: `" .. analysis.pattern .. "`\n\n"
        output = output .. "Risk factors:\n"
        for _, factor in ipairs(analysis.risk_factors) do
          output = output .. "- " .. factor .. "\n"
        end
        output = output .. "\n"
      end
    end
  end
  
  -- Also include a full listing in an appendix
  output = output .. "## Appendix: All Patterns\n\n"
  for i, pattern in ipairs(patterns) do
    output = output .. i .. ". `" .. pattern.source .. "`\n"
  end
  
  return output
end

local function analyze_highlights_file(file_path)
  log("Analyzing file: " .. file_path)
  
  -- Read file content
  local content = read_file(file_path)
  if not content then
    log("ERROR: Could not read file: " .. file_path)
    return
  end
  
  -- Extract patterns
  local patterns = extract_match_patterns(content)
  log("Found " .. #patterns .. " match patterns")
  
  -- Analyze each pattern
  local analyses = {}
  for _, pattern in ipairs(patterns) do
    log("Analyzing pattern: " .. pattern.pattern)
    local analysis = analyze_pattern(pattern)
    table.insert(analyses, analysis)
    
    if analysis.risk_level == "critical" or analysis.risk_level == "high" then
      log("WARNING: High-risk pattern found: " .. pattern.pattern)
      for _, factor in ipairs(analysis.risk_factors) do
        log("  - " .. factor)
      end
    end
  end
  
  -- Generate report
  local report = generate_report(file_path, patterns, analyses)
  
  -- Write report to file
  local output_path = "./consumables/test/highlights_analysis_report.md"
  local output_file = io.open(output_path, "w")
  if output_file then
    output_file:write(report)
    output_file:close()
    log("Report written to: " .. output_path)
  else
    log("ERROR: Could not write to output file")
  end
  
  return patterns, analyses
end

-- Look for highlights.scm files in the queries directory
local queries_path = vim.fn.stdpath("config") .. "/queries"
local spthy_highlights_path = queries_path .. "/spthy/highlights.scm"
local tamarin_highlights_path = queries_path .. "/tamarin/highlights.scm"

if vim.fn.filereadable(spthy_highlights_path) == 1 then
  log("Found spthy highlights.scm, analyzing...")
  analyze_highlights_file(spthy_highlights_path)
elseif vim.fn.filereadable(tamarin_highlights_path) == 1 then
  log("Found tamarin highlights.scm, analyzing...")
  analyze_highlights_file(tamarin_highlights_path)
else
  log("Could not find highlights.scm for spthy or tamarin")
  log("Please specify a path to analyze")
end 