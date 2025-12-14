#!/bin/bash

# Format Swift code using SwiftFormat 0.54.0
echo "Formatting Swift code..."

# Check if swiftformat is installed
if ! command -v swiftformat &> /dev/null; then
    echo "SwiftFormat not found."
    echo "Please install SwiftFormat 0.54.0:"
    echo "  brew install swiftformat"
    echo "  or download from https://github.com/nicklockwood/SwiftFormat/releases/tag/0.54.0"
    echo "Skipping Swift formatting..."
    exit 0
fi

# Format all Swift files in iOS packages
find packages -name "*.swift" -not -path "*/build/*" -not -path "*/.*" -not -path "*/Pods/*" | while read -r file; do
    swiftformat "$file" > /dev/null 2>&1 || true
done

echo "✓ Swift formatting complete"
