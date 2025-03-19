# Temporary Work Log

## 2023-05-22
- Created tracking files and hypothesis_testing directory
- Explored directory structure to understand the codebase
- Identified key files related to Tamarin TreeSitter integration:
  - lua/tamarin/init.lua: Main module for Tamarin setup
  - lua/tamarin/treesitter.lua: TreeSitter integration for Tamarin
  - lua/tamarin/parser_loader.lua: Complex parser loader module
  - parser/spthy/spthy.so: Tamarin parser compiled for spthy language
  - parser/tamarin/tamarin.so: Duplicate parser in tamarin directory
  - queries/spthy/highlights.scm: Current minimal query file
  - queries/tamarin/highlights.scm: Symlink to spthy highlights.scm
- Found multiple versions of highlights.scm files with different complexity levels
- Read key documentation files:
  - facts.md: Established facts about TreeSitter integration
  - pitfalls.md: Common pitfalls when working with TreeSitter
  - simplifying_the_config.md: Proposal to simplify parser loading
  - tamarin_treesitter_implementation_plan.md: Comprehensive implementation plan
- Added initial hypotheses to hypothesis_database.md
- Updated trawl_seed.md with relevant documentation links
- Identified potential issues:
  1. Parser symbol mismatch (`_tree_sitter_spthy` vs expected name)
  2. Language-to-filetype mapping issues (spthy vs tamarin)
  3. Complex regex patterns causing stack overflows
  4. Redundant parser files and symlinks
  5. Overly complex implementation that could be simplified

- Created first test: Symbol names in parser files
  - Confirmed H2, H3, and H5: The parsers are duplicates and export `_tree_sitter_spthy` not `tree_sitter_tamarin`
  - Confirmed that the language/filetype mismatch requires explicit mapping
  - Updated hypothesis_database.md with findings

- Backed up redundant files to create a cleaner structure:
  - Backed up parser/tamarin/tamarin.so to backup/parser/
  - Backed up parser/tamarin/tamarin-grammar.js to backup/parser/
  - Backed up all query files to backup/queries/spthy/ and backup/queries/tamarin/

- Created simplified modules based on the approach in simplifying_the_config.md:
  - lua/tamarin/simplified_loader.lua: Simplified parser loader
  - lua/tamarin/diagnostics.lua: Diagnostic utilities for troubleshooting
  - lua/tamarin/simplified.lua: New main module using the simplified approach
  - These modules provide the same functionality with cleaner, more maintainable code

