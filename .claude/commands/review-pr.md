# Review PR Comments

Review and address PR review comments for this repository.

> **Note:** This extends the global `/review-pr` command with project-specific checks.

## Arguments

- `$ARGUMENTS` - PR number (e.g., `123`) or PR URL

## Project-Specific Build Commands

Based on changed files, run these checks BEFORE committing:

| Changed Files | Commands |
|---------------|----------|
| `lib/*.dart` (except types.dart) | `git ls-files '*.dart' \| grep -v '^lib/types.dart$' \| xargs dart format --page-width 80 --output=none --set-exit-if-changed && flutter analyze && flutter test` |
| `android/` | `cd example && flutter build apk --debug` |
| `ios/` | `cd example && flutter build ios --no-codesign --debug` |
| `test/` | `flutter test` |

**Quick check script:** `./scripts/pre-commit-checks.sh`

## Project Conventions

When reviewing, check these project-specific rules:

- **iOS-related code**: Use `IOS` suffix (e.g., `PurchaseIOS`, `SubscriptionOfferIOS`)
- **Android-related code**: Use `Android` suffix (e.g., `PurchaseAndroid`)
- **ID convention**: Use `Id` consistently (e.g., `productId`, `transactionId`)
- **Generated files**: Do NOT edit `lib/types.dart` - regenerate via `./scripts/generate-type.sh`
- **API naming**: Use `request` prefix for event-dependent functions (e.g., `requestPurchase`)

See [CLAUDE.md](../../CLAUDE.md) for full conventions.

## Reply Format Rules (CRITICAL)

When replying to PR comments:

### Commit Hash Formatting

**NEVER wrap commit hashes in backticks or code blocks.** GitHub only auto-links plain text commit hashes.

| Format | Example | Result |
|--------|---------|--------|
| CORRECT | `Fixed in f3b5fec.` | Clickable link to commit |
| WRONG | `Fixed in \`f3b5fec\`.` | Plain text, no link |

**Examples of correct replies:**

```text
Fixed in f3b5fec.

**Changes:**
- Updated error handling for iOS purchases
```

```text
Fixed in abc1234 along with other review items.
```

**Do NOT use backticks around the commit hash** - this breaks GitHub's auto-linking feature.

## Workflow

1. Fetch unresolved PR review threads using `gh api`
2. For each comment:
   - **Valid issue** -> Fix the code
   - **Invalid/wrong** -> Reply with explanation (don't resolve)
3. Run pre-commit checks (format, analyze, test)
4. If all pass -> Commit and push
5. Resolve fixed threads with reply containing commit hash
