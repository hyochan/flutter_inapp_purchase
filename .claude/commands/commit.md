# Commit Changes

Complete workflow: branch check → pre-commit checks → commit → push → PR

## Usage

```
/commit [options]
```

**Options:**
- `--push` or `-p`: Push to remote after commit
- `--pr`: Create PR after push
- `--all` or `-a`: Commit all changes at once
- `<path>`: Commit only specific path (e.g., `lib/`)

## Examples

```bash
# Full workflow: commit lib changes, push, create PR
/commit lib/ --pr

# Commit all and create PR
/commit --all --pr

# Just commit specific path
/commit android/

# Push to remote after commit
/commit --push
```

## Complete Workflow

### 1. Check Branch

```bash
# Check current branch
git branch --show-current
```

**If on `main`** -> Create a feature branch first:
```bash
git checkout -b feat/<feature-name>
```

**If NOT on `main`** -> Proceed with commits directly.

**Branch naming conventions:**
- `feat/<feature-name>` - New features
- `fix/<bug-description>` - Bug fixes
- `docs/<doc-update>` - Documentation only
- `chore/<task>` - Maintenance tasks

### 2. Check Current Status

```bash
git status
git diff --name-only
```

### 3. Run Pre-Commit Checks (CRITICAL)

**Before committing, ALL checks must pass:**

```bash
# 1. Format check (skip generated types.dart)
git ls-files '*.dart' | grep -v '^lib/types.dart$' | xargs dart format --page-width 80 --output=none --set-exit-if-changed

# 2. Lint check
flutter analyze

# 3. Test validation
flutter test
```

**If format check fails:**
```bash
# Auto-format and retry
git ls-files '*.dart' | grep -v '^lib/types.dart$' | xargs dart format --page-width 80
```

**Alternative:** Run `./scripts/pre-commit-checks.sh` for all checks at once.

### 4. Stage Changes

**Specific path:**
```bash
git add <path>
```

**All changes:**
```bash
git add .
```

### 5. Review Staged Changes

```bash
git diff --cached --stat
git diff --cached --name-only
```

### 6. Create Commit

Follow conventional commit format:

```bash
git commit -m "$(cat <<'EOF'
<type>: <description>

<body - what changed and why>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

**Commit Types:**
| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code refactoring |
| `chore` | Maintenance tasks |
| `test` | Adding/updating tests |

### 7. Push to Remote

```bash
git push -u origin <branch-name>
```

### 8. Create Pull Request

```bash
gh pr create --title "<type>: <description>" --body "$(cat <<'EOF'
## Summary

<1-3 bullet points describing changes>

## Changes

- Change 1
- Change 2

## Test plan

- [ ] `dart format --set-exit-if-changed .` passes
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes

Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

---

## Commit Order (For Cross-Platform Changes)

When making changes across platforms, commit in this order:

| Order | Path | Description |
|-------|------|-------------|
| 1 | `lib/` | Dart library code (excluding types.dart) |
| 2 | `android/` | Android implementation |
| 3 | `ios/` | iOS implementation |
| 4 | `example/` | Example app changes |
| 5 | `test/` | Test updates |
| 6 | Root files | pubspec.yaml, README.md, etc. |

**IMPORTANT - Never edit `lib/types.dart`:**
This file is auto-generated. Regenerate via `./scripts/generate-type.sh`.

---

## Example Commit Messages

**New feature:**
```
feat: add subscription offer support

- Add SubscriptionOfferIOS for iOS promotional offers
- Add SubscriptionOfferAndroid for Android offers
- Update fetchProducts to include offer details

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Bug fix:**
```
fix: resolve purchase validation error on iOS

- Handle edge case where transaction ID is null
- Add proper error handling for StoreKit exceptions

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Documentation:**
```
docs: update API documentation for getAvailablePurchases

- Add PurchaseOptions parameter documentation
- Include iOS-specific behavior notes

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Chore:**
```
chore: bump version to 8.2.6

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

---

## Example PR Body

```markdown
## Summary

- Add win-back offer support for iOS 18+
- Improve error handling for Android purchase flow
- Update documentation with new API examples

## Changes

### Dart Library (lib/)
- Add `WinBackOfferIOS` type
- Update `requestPurchase` to support offers

### iOS (ios/)
- Implement StoreKit 2 win-back offer handling
- Add offer eligibility checking

### Android (android/)
- Improve BillingClient error mapping
- Add retry logic for transient failures

## Test plan

- [x] `dart format --set-exit-if-changed .` passes
- [x] `flutter analyze` passes
- [x] `flutter test` passes

Generated with [Claude Code](https://claude.ai/code)
```

---

## Quick Reference

```bash
# Full workflow from main
git checkout -b feat/my-feature

# Run pre-commit checks
./scripts/pre-commit-checks.sh

# Stage and commit
git add lib/
git commit -m "feat: add new feature"

git add android/ ios/
git commit -m "feat: implement native support"

git add test/
git commit -m "test: add unit tests"

# Push and create PR
git push -u origin feat/my-feature
gh pr create --title "feat: add new feature" --body "..."
```
