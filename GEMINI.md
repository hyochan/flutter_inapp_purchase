# Gemini Configuration for flutter_inapp_purchase

This file provides context and instructions for the Gemini CLI when working with this repository.

## Project Overview

This is a Flutter plugin for In-App Purchases (IAP) that provides a unified API for both iOS and Android platforms. The plugin follows the OpenIAP specification for standardized IAP implementation.

## Key Guidelines

### Code Standards

1. **API Design**: Follow the simplified API design where methods use direct parameters instead of parameter objects (see CLAUDE.md for details)
2. **Platform Naming**: Use consistent platform suffixes (IOS for iOS, Android for Android)
3. **Testing**: All changes must pass `flutter test`
4. **Formatting**: Code must be formatted with `dart format`
5. **Linting**: Code should pass `flutter analyze`

### Before Making Changes

1. Read the existing CLAUDE.md file for detailed implementation guidelines
2. Check existing code patterns in similar files
3. Ensure backward compatibility unless breaking changes are explicitly requested
4. Follow the OpenIAP specification: <https://www.openiap.dev/docs/apis>

### PR Creation Guidelines

When creating PRs to fix issues:

1. **Branch Naming**: Use `fix-issue-<number>` for bug fixes, `feat-issue-<number>` for features
2. **Commit Messages**: Be descriptive and reference the issue number
3. **Testing**: Add tests for new functionality or bug fixes
4. **Documentation**: Update relevant documentation if API changes are made
5. **Verification**: Run all checks before creating the PR:
   - `dart format --set-exit-if-changed .`
   - `flutter analyze`
   - `flutter test`

### Issue Analysis

When analyzing issues for automatic resolution:

1. **Solvable Issues**:

   - Clear bug reports with reproducible steps
   - Simple feature requests with well-defined scope
   - Documentation updates
   - Code formatting or linting issues
   - Missing type annotations or small refactoring tasks

2. **Non-Solvable Issues** (require human intervention):
   - Major architectural changes
   - Breaking API changes without clear migration path
   - Issues requiring business logic decisions
   - Platform-specific issues requiring device testing
   - Issues with insufficient information

### Code Modification Rules

1. **Preserve Existing Patterns**: Match the coding style of surrounding code
2. **Minimal Changes**: Make the smallest change necessary to fix the issue
3. **Test Coverage**: Ensure new code is covered by tests
4. **Error Handling**: Add appropriate error handling for edge cases
5. **Comments**: Add comments only for complex logic that isn't self-explanatory

### Common Tasks

#### Adding a New Feature

1. Check if it aligns with OpenIAP specification
2. Implement for both iOS and Android platforms if applicable
3. Add comprehensive tests
4. Update example app if needed
5. Document in README or API docs

#### Fixing a Bug

1. Reproduce the issue first
2. Write a failing test that demonstrates the bug
3. Fix the bug
4. Ensure the test now passes
5. Run all existing tests to ensure no regression

#### Updating Dependencies

1. Check compatibility with Flutter stable channel
2. Update pubspec.yaml
3. Run `flutter pub get`
4. Test thoroughly
5. Update CHANGELOG.md

## Repository Structure

- `/lib`: Main plugin implementation
- `/android`: Android platform-specific code
- `/ios`: iOS platform-specific code
- `/example`: Example Flutter app demonstrating plugin usage
- `/test`: Unit and integration tests
- `/docs`: Additional documentation

## Important Files

- `CLAUDE.md`: Detailed implementation guidelines and conventions
- `pubspec.yaml`: Package dependencies and metadata
- `CHANGELOG.md`: Version history and changes
- `.github/workflows/ci.yml`: CI pipeline configuration
