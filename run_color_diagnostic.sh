#!/bin/bash

# Run Tamarin Color Diagnostic
# This script diagnoses issues with Tamarin syntax highlighting colors

echo "Running color diagnostic for Tamarin/Spthy files..."
echo "=================================================="

# Run the diagnostic script headlessly with a timeout
# Use -n flag to avoid loading vimrc file which might affect diagnoses
timeout 30s nvim --headless -n -u NONE --cmd 'set t_ti= t_te= nomore' -c "luafile syntax_color_diagnostic.lua" > color_diagnostic_output.txt 2>&1

# Check for timeout
if [ $? -eq 124 ]; then
  echo "Error: Diagnostic timed out after 30 seconds!"
  echo "This indicates a problem with the diagnostic script or Neovim configuration."
  exit 1
fi

# Display the diagnostic output
cat color_diagnostic_output.txt

# Check if report was generated
if [ -f "color_diagnostic_report.md" ]; then
  echo ""
  echo "Detailed diagnostic report saved to color_diagnostic_report.md"
else
  echo ""
  echo "Warning: No diagnostic report was generated!"
fi

echo ""
echo "Next Steps:"
echo "1. Review the diagnosis above to understand the syntax highlighting conflict"
echo "2. Edit ftplugin/spthy.vim to fix the configuration issue"
echo "3. Run this diagnostic again to verify the fix" 