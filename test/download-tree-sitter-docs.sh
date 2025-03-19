#!/bin/bash

# Base URL for Tree-sitter documentation on GitHub
BASE_URL="https://raw.githubusercontent.com/tree-sitter/tree-sitter.github.io/master/docs"

# Directory to save files
OUTPUT_DIR="./consumables"

# Create directories if they don't exist
mkdir -p "$OUTPUT_DIR/using-parsers/queries"
mkdir -p "$OUTPUT_DIR/creating-parsers"
mkdir -p "$OUTPUT_DIR/cli"

# Download files
# Introduction
curl -s "$BASE_URL/index.md" -o "$OUTPUT_DIR/index.md"

# Using Parsers
curl -s "$BASE_URL/using-parsers/index.md" -o "$OUTPUT_DIR/using-parsers/index.md"
curl -s "$BASE_URL/using-parsers/1-getting-started.md" -o "$OUTPUT_DIR/using-parsers/1-getting-started.md"
curl -s "$BASE_URL/using-parsers/2-basic-parsing.md" -o "$OUTPUT_DIR/using-parsers/2-basic-parsing.md"
curl -s "$BASE_URL/using-parsers/3-advanced-parsing.md" -o "$OUTPUT_DIR/using-parsers/3-advanced-parsing.md"
curl -s "$BASE_URL/using-parsers/4-walking-trees.md" -o "$OUTPUT_DIR/using-parsers/4-walking-trees.md"
curl -s "$BASE_URL/using-parsers/6-static-node-types.md" -o "$OUTPUT_DIR/using-parsers/6-static-node-types.md"

# Queries
curl -s "$BASE_URL/using-parsers/queries/index.md" -o "$OUTPUT_DIR/using-parsers/queries/index.md"
curl -s "$BASE_URL/using-parsers/queries/1-syntax.md" -o "$OUTPUT_DIR/using-parsers/queries/1-syntax.md"
curl -s "$BASE_URL/using-parsers/queries/2-operators.md" -o "$OUTPUT_DIR/using-parsers/queries/2-operators.md"
curl -s "$BASE_URL/using-parsers/queries/3-predicates-and-directives.md" -o "$OUTPUT_DIR/using-parsers/queries/3-predicates-and-directives.md"
curl -s "$BASE_URL/using-parsers/queries/4-api.md" -o "$OUTPUT_DIR/using-parsers/queries/4-api.md"

# Creating Parsers
curl -s "$BASE_URL/creating-parsers/index.md" -o "$OUTPUT_DIR/creating-parsers/index.md"
curl -s "$BASE_URL/creating-parsers/1-getting-started.md" -o "$OUTPUT_DIR/creating-parsers/1-getting-started.md"
curl -s "$BASE_URL/creating-parsers/2-the-grammar-dsl.md" -o "$OUTPUT_DIR/creating-parsers/2-the-grammar-dsl.md"
curl -s "$BASE_URL/creating-parsers/3-writing-the-grammar.md" -o "$OUTPUT_DIR/creating-parsers/3-writing-the-grammar.md"
curl -s "$BASE_URL/creating-parsers/4-external-scanners.md" -o "$OUTPUT_DIR/creating-parsers/4-external-scanners.md"
curl -s "$BASE_URL/creating-parsers/5-writing-tests.md" -o "$OUTPUT_DIR/creating-parsers/5-writing-tests.md"
curl -s "$BASE_URL/creating-parsers/6-publishing.md" -o "$OUTPUT_DIR/creating-parsers/6-publishing.md"

# Other main docs
curl -s "$BASE_URL/3-syntax-highlighting.md" -o "$OUTPUT_DIR/3-syntax-highlighting.md"
curl -s "$BASE_URL/4-code-navigation.md" -o "$OUTPUT_DIR/4-code-navigation.md"
curl -s "$BASE_URL/5-implementation.md" -o "$OUTPUT_DIR/5-implementation.md"
curl -s "$BASE_URL/6-contributing.md" -o "$OUTPUT_DIR/6-contributing.md"
curl -s "$BASE_URL/7-playground.md" -o "$OUTPUT_DIR/7-playground.md"

# CLI docs
curl -s "$BASE_URL/cli/index.md" -o "$OUTPUT_DIR/cli/index.md"
curl -s "$BASE_URL/cli/init-config.md" -o "$OUTPUT_DIR/cli/init-config.md"
curl -s "$BASE_URL/cli/init.md" -o "$OUTPUT_DIR/cli/init.md"
curl -s "$BASE_URL/cli/generate.md" -o "$OUTPUT_DIR/cli/generate.md"
curl -s "$BASE_URL/cli/build.md" -o "$OUTPUT_DIR/cli/build.md"
curl -s "$BASE_URL/cli/parse.md" -o "$OUTPUT_DIR/cli/parse.md"
curl -s "$BASE_URL/cli/test.md" -o "$OUTPUT_DIR/cli/test.md"
curl -s "$BASE_URL/cli/version.md" -o "$OUTPUT_DIR/cli/version.md"
curl -s "$BASE_URL/cli/fuzz.md" -o "$OUTPUT_DIR/cli/fuzz.md"
curl -s "$BASE_URL/cli/query.md" -o "$OUTPUT_DIR/cli/query.md"
curl -s "$BASE_URL/cli/highlight.md" -o "$OUTPUT_DIR/cli/highlight.md"
curl -s "$BASE_URL/cli/tags.md" -o "$OUTPUT_DIR/cli/tags.md"
curl -s "$BASE_URL/cli/playground.md" -o "$OUTPUT_DIR/cli/playground.md"
curl -s "$BASE_URL/cli/dump-languages.md" -o "$OUTPUT_DIR/cli/dump-languages.md"
curl -s "$BASE_URL/cli/complete.md" -o "$OUTPUT_DIR/cli/complete.md"

echo "All Tree-sitter documentation files have been downloaded to $OUTPUT_DIR" 