# Implementation Guidelines

## API Changes

### fetchProducts API (Updated)

The `fetchProducts` method is a generic method. Use explicit type parameter for proper type inference:

```dart
// For InApp products - specify <Product>
final products = await iap.fetchProducts<Product>(
  skus: ['product_id_1', 'product_id_2'],
  type: ProductQueryType.InApp, // Optional, defaults to InApp
);

// For subscriptions - specify <ProductSubscription>
final subscriptions = await iap.fetchProducts<ProductSubscription>(
  skus: ['sub_id_1', 'sub_id_2'],
  type: ProductQueryType.Subs,
);

// For all products - specify <ProductCommon>
final allProducts = await iap.fetchProducts<ProductCommon>(
  skus: [...],
  type: ProductQueryType.All,
);

// Simple iteration with type safety
for (final product in products) {
  print('${product.title}: ${product.displayPrice}');
}
```

**Note:** Always use explicit type parameter for proper type inference and IDE support.

### getAvailablePurchases API (v6.4.6+)

The `getAvailablePurchases` method now supports `PurchaseOptions` for OpenIAP compliance:

```dart
// Get active purchases only (default behavior)
final activePurchases = await iap.getAvailablePurchases();

// Get all purchases including expired subscriptions (iOS)
final allPurchases = await iap.getAvailablePurchases(
  PurchaseOptions(
    onlyIncludeActiveItemsIOS: false,  // Include expired subscriptions
    alsoPublishToEventListenerIOS: true,  // Optional: publish to event listener
  ),
);
```

**Note**: `getPurchaseHistories()` is deprecated. Use `getAvailablePurchases()` with options instead.

## Flutter-Specific Guidelines

### Generated Files

- `lib/types.dart` is generated from the OpenIAP schema. Never edit it by hand.
- Always regenerate via `./scripts/generate-type.sh` so the file stays in sync with the upstream `openiap-dart` package.
- If the generation script fails, fix the script or the upstream source instead of patching the output manually.

### Using `lib/types.dart`

- Follow the generated-handler convention documented in `CONVENTION.md` so exported APIs stay aligned with the OpenIAP schema.

### Documentation Style

- **Avoid using emojis** in documentation, especially in headings
- Keep documentation clean and professional for better readability
- Focus on clear, concise technical writing

### Pre-Commit Checks

**Pre-commit hooks are now set up** to automatically run these checks before each commit. If any check fails, the commit will be blocked.

Before committing any changes, run these commands in order and ensure ALL pass:

1. **Format check**: `git ls-files '*.dart' | grep -v '^lib/types.dart$' | xargs dart format --page-width 80 --output=none --set-exit-if-changed`
   - This matches the CI formatter and skips the generated `lib/types.dart`
   - If it fails, run the same command without `--set-exit-if-changed` (or drop the `--output` flag) to auto-format, then retry
   - Always format code before committing to maintain consistent style
2. **Lint check**: `flutter analyze`
   - Fix any lint issues before committing
   - Pay attention to type inference errors and explicitly specify type arguments when needed
3. **Test validation**: `flutter test`
   - All tests must pass
   - When you need coverage data, run `flutter test --coverage` then `dart run tool/filter_coverage.dart` to strip `lib/types.dart` from reports
4. **Final verification**: Re-run `dart format --set-exit-if-changed .` to confirm no formatting issues
5. Only commit if ALL checks succeed with exit code 0

**Manual check script**: You can also run `./scripts/pre-commit-checks.sh` to manually execute all checks.

### Commit Message Convention

- Follow the Angular commit style: `<type>: <short summary>` (50 characters max).
- Use lowercase `type` (e.g., `feat`, `fix`, `docs`, `chore`, `test`).
- Keep the summary concise and descriptive; avoid punctuation at the end.

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

- Functions that depend on event results should use `request` prefix (e.g., `requestPurchase`, `requestPurchaseWithBuilder`)
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
