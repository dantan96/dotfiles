# Tamarin Syntax Highlighting Validation System

This set of tools helps diagnose and fix syntax highlighting issues for Tamarin Protocol Verification (spthy) files in Neovim.

## The Problem

Tamarin/spthy syntax highlighting should match the colors defined in:
- `/Users/dan/.config/nvim/lua/config/spthy-colorscheme.lua` (color definitions)
- `/Users/dan/.config/nvim/lua/config/tamarin-colors.lua` (highlight group mappings)

However, sometimes the actual colors applied by Neovim (either via TreeSitter or regular syntax highlighting) don't match these definitions.

## The Solution: A Diagnostic Workflow

This system provides a complete workflow to:
1. Validate that syntax elements receive the correct highlighting
2. Identify discrepancies between expected and actual colors
3. Suggest improvements to TreeSitter's highlight configuration

## Components

### Validation Scripts
- `validate_syntax_colors.lua` - Core script that checks highlighting against expected colors
- `validate_highlighting.sh` - Shell wrapper for headless validation
- `run_highlight_test.lua` - Simpler version for quick testing

### Analysis & Improvement
- `update_highlights.lua` - Analyzes validation results and suggests TreeSitter improvements
- `treesitter_suggestions.md` - Generated file with recommendations for highlights.scm

### Complete Workflow
- `tamarin_syntax_workflow.sh` - Comprehensive script that runs validation and analysis in sequence

## How to Use

### Quick Start
Simply run the workflow script:
```bash
./tamarin_syntax_workflow.sh
```

This will:
1. Run validation on `test.spthy`
2. Generate detailed reports
3. Analyze issues and suggest improvements

### Manual Usage

#### Validation Only
```bash
./validate_highlighting.sh
```

#### Analysis Only
```bash
nvim --headless -u NONE -c "luafile update_highlights.lua"
```

## Output Files
- `syntax_validation_results.md` - Detailed validation report
- `validation_output.txt` - Console output from validation 
- `treesitter_suggestions.md` - Suggested improvements for `highlights.scm`
- `analysis_output.txt` - Console output from analysis

## Development Cycle

1. Run the workflow to identify issues
2. Review suggestions in `treesitter_suggestions.md`
3. Edit `/Users/dan/.config/nvim/queries/spthy/highlights.scm` to fix issues
4. Run the workflow again to verify improvements
5. Repeat until all highlighting matches the expected configuration 