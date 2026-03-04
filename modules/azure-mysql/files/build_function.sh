#!/bin/bash
#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
# Build Azure Function package for MySQL VA Configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTION_DIR="$SCRIPT_DIR/../MySQLVAConfig"
OUTPUT_ZIP="$SCRIPT_DIR/function.zip"

echo "Building Azure Function package..."
echo "Function directory: $FUNCTION_DIR"
echo "Output: $OUTPUT_ZIP"

# Remove old zip if exists
rm -f "$OUTPUT_ZIP"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "Temporary directory: $TEMP_DIR"

# Copy function directory structure
mkdir -p "$TEMP_DIR/MySQLVAConfig"
cp "$FUNCTION_DIR/__init__.py" "$TEMP_DIR/MySQLVAConfig/"
cp "$FUNCTION_DIR/function.json" "$TEMP_DIR/MySQLVAConfig/"
cp "$FUNCTION_DIR/requirements.txt" "$TEMP_DIR/"
cp "$FUNCTION_DIR/host.json" "$TEMP_DIR/"

# Create the zip package
cd "$TEMP_DIR"
zip -r "$OUTPUT_ZIP" . -x "*.DS_Store"

# Clean up
rm -rf "$TEMP_DIR"

echo "✓ Function package created: $OUTPUT_ZIP"
echo "Package size: $(du -h "$OUTPUT_ZIP" | cut -f1)"
