# Debug Tracker

This file tracks all debug-related code and files that we'll need to clean up once the issues are resolved.

## Temporary Files

| File | Purpose | Status |
|------|---------|--------|
| `/tmp/nvim-debug-logs/` | Directory for deep_debug.sh logs | Active |
| `/tmp/tamarin-debug/` | Directory for parser loading tests | Planned |
| `queries/spthy/highlights.scm.ultra_minimal` | Test minimal highlighting | Active |

## Debug Code Added

| File | Function/Line | Purpose | Status |
|------|---------------|---------|--------|
| `deep_debug.sh` | entire file | Comprehensive debugging tool | Active |
| `lua/debug/deep_trace.lua` | entire file | Debug module for deep_debug.sh | Active |

## Logging Statements to Remove

None yet - we will use the new parser_loader.lua file instead of adding debug prints to existing files.

## Testing Files

| File | Purpose | Status |
|------|---------|--------|
| `run_nvim.sh` | Basic testing script | Active |
| `documentation/professionalAttempt/test.spthy` | Test file with apostrophes | Active |

## Planned Debug Tools

| Tool | Purpose | Status |
|------|---------|--------|
| `lua/parser_loader.lua` | Parser loading with debug logging | Planned |
| `queries/spthy/highlights.scm.XX_variant` | Various test highlight files | Planned |

## Cleanup Checklist

- [ ] Remove all temporary debug files
- [ ] Remove debug print statements
- [ ] Remove test files
- [ ] Keep only the final, working highlights.scm
- [ ] Document the solution 