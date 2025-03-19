#!/bin/bash

# Script to revert to a working version of the highlights.scm file

ORIGINAL_FILE="queries/spthy/highlights.scm"
BACKUP_FILE="queries/spthy/highlights.scm.backup"

echo "Creating backup of current highlights.scm file..."
if [ -f "$ORIGINAL_FILE" ]; then
  cp "$ORIGINAL_FILE" "$BACKUP_FILE"
  echo "Backup created at $BACKUP_FILE"
else
  echo "Warning: Original file not found at $ORIGINAL_FILE"
fi

echo "Reverting to the minimal working version (commit 96c626a)..."
git show 96c626a:queries/spthy/highlights.scm > "$ORIGINAL_FILE"

echo "Done. The highlights.scm file has been reverted to a minimal working version."
echo "The original file has been backed up to $BACKUP_FILE."
echo "After completing the documentation reading list, you can restore it or create a better version." 