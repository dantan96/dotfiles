# Hypotheses for TreeSitter Fallback to Traditional Highlighting

This document contains hypotheses about why TreeSitter syntax highlighting might not be working for the Tamarin test.spthy file despite our fixes to the parser loading process, causing it to fall back to traditional syntax highlighting.

## Hypothesis 1: Parser Loading Path Issues

**Description**: The parser might not be found in the specific path used when opening files in the `./documentation/professionalAttempt/` directory.

**Evidence Needed**:
- Check if parser files are in the runtime path when opening a file in that directory
- Verify the parser search paths when loading files from subdirectories
- Check if the relative paths are being resolved correctly

**Testing Plan**:
1. Create a test script that prints all parser search paths when opening a file in that directory
2. Check if the parser files are found in those paths
3. Verify if the parser is being correctly loaded for that specific buffer

## Hypothesis 2: Filetype Detection Issues

**Description**: The filetype might not be detected correctly for files in the `./documentation/professionalAttempt/` directory.

**Evidence Needed**:
- Check what filetype is assigned to the buffer when opening the file
- Verify if filetype detection patterns match files in subdirectories
- Check if there are conflicting filetype assignments

**Testing Plan**:
1. Create a test script that prints the filetype of the buffer when opening that file
2. Check if the file pattern matching for 'tamarin' filetype includes full paths
3. Verify if another filetype is being assigned instead

## Hypothesis 3: TreeSitter Registration Not Happening for Specific Paths

**Description**: The code that registers TreeSitter for Tamarin files might not be triggered for files in that specific path.

**Evidence Needed**:
- Check if our TreeSitter setup code runs for files in that directory
- Verify if the autocommand patterns match files in subdirectories
- Check if there are path-specific issues in the autocommand matching

**Testing Plan**:
1. Add logging to the autocommand callback to see if it's triggered for that file
2. Try manually running the setup code when that file is open
3. Check if the autocommand pattern needs to be adjusted to match all file paths

## Hypothesis 4: Grammar Parsing Errors for Complex Files

**Description**: The parser might be loading correctly but failing to parse the specific syntax in the test file, causing a fallback to traditional highlighting.

**Evidence Needed**:
- Check if the parser returns ERROR nodes for the specific file
- Verify if there are specific syntax constructs in the file that cause parsing errors
- Check if simpler files parse correctly but complex ones don't

**Testing Plan**:
1. Create a test script that inspects the parse tree for that specific file
2. Try parsing progressively simpler versions of the file to isolate problematic syntax
3. Verify if the ERROR nodes correspond to specific syntax constructs

## Hypothesis 5: Highlighting Query Not Matching Node Types

**Description**: The highlights.scm query might not contain patterns that match the node types produced by the parser for specific syntax constructs in the test file.

**Evidence Needed**:
- Check what node types are produced by the parser for that file
- Verify if the highlights.scm file has patterns for those node types
- Check if the query is being applied correctly

**Testing Plan**:
1. Use a TreeSitter playground or custom script to inspect node types
2. Compare node types with the patterns in highlights.scm
3. Check if adding specific patterns for those node types fixes the highlighting

## Hypothesis 6: Multiple Instances of Setup Code Running

**Description**: There might be multiple instances of our setup code running, with later ones overriding or conflicting with earlier ones.

**Evidence Needed**:
- Check if there are multiple setup calls for the same buffer
- Verify if there are conflicting configurations being applied
- Check the sequence of initialization calls

**Testing Plan**:
1. Add sequence numbers to log messages to track the order of setup calls
2. Check if multiple instances of setup code are being called for the same buffer
3. Verify if later calls are undoing the work of earlier ones

## Hypothesis 7: Explicit Fallback Being Triggered

**Description**: Our code might be explicitly falling back to traditional highlighting due to some condition being met.

**Evidence Needed**:
- Check the conditions under which the fallback is triggered
- Verify if any of those conditions are being met for this file
- Check if the fallback is being explicitly requested

**Testing Plan**:
1. Add detailed logging around the fallback decision points
2. Check what specific condition is triggering the fallback
3. Verify if that condition can be avoided or fixed

## Hypothesis 8: Traditional Syntax File Taking Precedence

**Description**: There might be a traditional syntax file (e.g., syntax/tamarin.vim) that is taking precedence over TreeSitter highlighting.

**Evidence Needed**:
- Check if traditional syntax files exist for Tamarin
- Verify if they're being loaded for files in that directory
- Check if there's a mechanism that prioritizes them over TreeSitter

**Testing Plan**:
1. Search for traditional syntax files in the runtime path
2. Check if they're being loaded for that specific buffer
3. Try temporarily disabling them to see if TreeSitter highlighting takes effect

## Hypothesis 9: TreeSitter Highlighting Disabled for That Buffer

**Description**: TreeSitter highlighting might be explicitly disabled for buffers in that directory or with certain properties.

**Evidence Needed**:
- Check if there are any settings that disable TreeSitter highlighting
- Verify if those settings are applied to buffers in that directory
- Check if there are filetype-specific or pattern-specific disabling mechanisms

**Testing Plan**:
1. Check the value of TreeSitter-related settings for that buffer
2. Try explicitly enabling TreeSitter highlighting for that buffer
3. Verify if any plugins or configurations are disabling it

## Hypothesis 10: Error in Query Causing Silent Fallback

**Description**: There might be an error in the query file that causes TreeSitter highlighting to silently fail and fall back.

**Evidence Needed**:
- Check if there are errors when loading the query file
- Verify if those errors are being suppressed
- Check if the query file is syntactically valid

**Testing Plan**:
1. Add error checking and logging when loading the query file
2. Try with a known-good minimal query file
3. Check for syntax errors or invalid patterns in the query file 