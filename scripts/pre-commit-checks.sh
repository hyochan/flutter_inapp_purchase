#!/bin/bash

echo "Running pre-commit checks..."

# Format check
echo "Checking code formatting..."
if ! git ls-files '*.dart' | grep -v '^lib/types.dart$' | xargs dart format --page-width 80 --output=none --set-exit-if-changed; then
    echo "❌ Code formatting check failed. Please run: git ls-files '*.dart' | grep -v '^lib/types.dart$' | xargs dart format --page-width 80"
    exit 1
fi

# Lint check
echo "Running flutter analyze..."
if ! flutter analyze; then
    echo "❌ Flutter analyze failed. Please fix the linting issues."
    exit 1
fi

# Test validation
echo "Running flutter test..."
if ! flutter test; then
    echo "❌ Tests failed. Please fix the failing tests."
    exit 1
fi

# Final verification
echo "Final format verification..."
if ! dart format --set-exit-if-changed .; then
    echo "❌ Final format verification failed. Please run: dart format ."
    exit 1
fi

echo "✅ All pre-commit checks passed!"
exit 0