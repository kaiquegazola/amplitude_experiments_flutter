#!/bin/bash

# Format Kotlin code using ktlint 1.3.0
echo "Formatting Kotlin code..."

# Check if ktlint is installed
if ! command -v ktlint &> /dev/null; then
    echo "ktlint not found. Installing ktlint 1.3.0..."

    # Download ktlint if not present
    if [ ! -f "scripts/ktlint" ]; then
        curl -sSLO https://github.com/pinterest/ktlint/releases/download/1.3.0/ktlint
        chmod a+x ktlint
        mv ktlint scripts/
    fi
    KTLINT="scripts/ktlint"
else
    KTLINT="ktlint"
fi

# Format all Kotlin files in Android packages
find packages -name "*.kt" -not -path "*/build/*" -not -path "*/.*" | while read -r file; do
    $KTLINT -F "$file" > /dev/null 2>&1 || true
done

echo "✓ Kotlin formatting complete"
