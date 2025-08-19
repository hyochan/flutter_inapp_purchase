# Implementation Guidelines

## Flutter-Specific Guidelines

### Documentation Style

- **Avoid using emojis** in documentation, especially in headings
- Keep documentation clean and professional for better readability
- Focus on clear, concise technical writing

### Pre-Commit Checks

Before committing any changes, run these commands in order and ensure ALL pass:

1. **Format check**: `dart format --set-exit-if-changed .`
   - This will fail if any files need formatting (exit code 1)
   - If it fails, run `dart format .` to fix formatting, then retry
   - Always format code before committing to maintain consistent style
2. **Lint check**: `flutter analyze`
   - Fix any lint issues before committing
   - Pay attention to type inference errors and explicitly specify type arguments when needed
3. **Test validation**: `flutter test`
   - All tests must pass
4. **Final verification**: Re-run `dart format --set-exit-if-changed .` to confirm no formatting issues
5. Only commit if ALL checks succeed with exit code 0

**Important**: 
- Use `--set-exit-if-changed` flag to match CI behavior and catch formatting issues locally before they cause CI failures
- When using generic functions like `showModalBottomSheet`, always specify explicit type arguments (e.g., `showModalBottomSheet<void>`) to avoid type inference errors

### Platform-Specific Naming Conventions

- **iOS-related code**: Use `IOS` suffix (e.g., `PurchaseIOS`, `SubscriptionOfferIOS`)
  - When iOS is not the final suffix, use `Ios` (e.g., `IosManager`, `IosHelper`)
  - For field names with iOS in the middle: use `Id` before `IOS` (e.g., `subscriptionGroupIdIOS`, `webOrderLineItemIdIOS`)
- **Android-related code**: Use `Android` suffix (e.g., `PurchaseAndroid`, `SubscriptionOfferAndroid`)
- **IAP-related code**: When IAP is not the final suffix, use `Iap` (e.g., `IapPurchase`, not `IAPPurchase`)
- **ID vs Id convention**: 
  - Use `Id` consistently across all platforms (e.g., `productId`, `transactionId`, `offerId`)
  - When combined with platform suffixes: use `Id` before the suffix (e.g., `subscriptionGroupIdIOS`, `webOrderLineItemIdIOS`, `obfuscatedAccountIdAndroid`)
  - Exception: Standalone iOS fields that end with ID use `ID` (e.g., `transactionID`, `webOrderLineItemID` in iOS-only contexts)
- This applies to both functions and types

### API Method Naming

- Functions that depend on event results should use `request` prefix (e.g., `requestPurchase`, `requestSubscription`)
- Follow OpenIAP terminology: <https://www.openiap.dev/docs/apis#terminology>
- Do not use generic prefixes like `get`, `find` - refer to the official terminology

## IAP-Specific Guidelines

### OpenIAP Specification

All implementations must follow the OpenIAP specification:

- **APIs**: <https://www.openiap.dev/docs/apis>
- **Types**: <https://www.openiap.dev/docs/types>
- **Events**: <https://www.openiap.dev/docs/events>
- **Errors**: <https://www.openiap.dev/docs/errors>

### Feature Development Process

For new feature proposals:

1. Before implementing, discuss at: <https://github.com/hyochan/openiap.dev/discussions>
2. Get community feedback and consensus
3. Ensure alignment with OpenIAP standards
4. Implement following the agreed specification
