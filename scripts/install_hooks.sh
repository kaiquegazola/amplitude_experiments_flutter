#!/bin/bash

# Install git hooks for amplitude_experiments_flutter

echo "Installing git hooks..."

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
cp scripts/pre-commit .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit

echo "✓ Git hooks installed successfully!"
echo ""
echo "The pre-commit hook will now run formatters before each commit."
echo "To bypass the hook (not recommended), use: git commit --no-verify"
