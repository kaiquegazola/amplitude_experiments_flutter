#!/bin/bash

# Format Dart code in all packages
echo "Formatting Dart code..."

# Format all Dart files in packages directory
dart format packages/ > /dev/null 2>&1

echo "✓ Dart formatting complete"
