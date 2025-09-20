# Conventions

## Using `lib/types.dart`

Prefer the generated handler typedefs and helper classes from `lib/types.dart` whenever you expose IAP APIs from this package. They track the OpenIAP schema and guarantee consistent parameter and return shapes across the codebase.

### Preferred pattern

```dart
final queryHandlers = QueryHandlers(
  fetchProducts: ({required ProductRequest params}) async {
    return _platform.fetchProducts(params: params);
  },
);

final mutationHandlers = MutationHandlers(
  finishTransaction: ({
    required PurchaseInput purchase,
    bool? isConsumable,
  }) async {
    return _platform.finishTransaction(
      purchase: purchase,
      isConsumable: isConsumable,
    );
  },
);
```

The generated signatures (`QueryFetchProductsHandler`, `MutationFinishTransactionHandler`, etc.) keep API contracts in sync with the schema. They also surface nullability, optional flags, and platform-specific fields without repeating boilerplate.

### Keep API surfaces self-contained

- `lib/flutter_inapp_purchase.dart` should expose only the generated API handlers. Avoid introducing private helper methods inside that file; derive request payloads inline or delegate to shared helpers in `lib/helpers.dart` when logic needs to be shared.
- When a reusable helper becomes unavoidable, place it in `lib/utils.dart` (or the relevant platform module) so the primary API surface stays aligned with the generated schema.

### Avoid manual shapes

```dart
Future<Map<String, dynamic>> fetchProducts(
  Map<String, dynamic> request,
) async {
  // ...
}

Future<void> finishTransaction(Map<String, dynamic> args) async {
  // ...
}
```

Hand-written maps or ad-hoc DTOs drift from the generated schema and are harder to maintain. Import `lib/types.dart` and wire the provided handler typedefs instead of recreating argument or result types.

### Keep throwaway helpers local

- If a helper is only used inside a single method (less than three call sites), prefer declaring it inside that method instead of adding private class-level or top-level functions. This keeps utility clutter down and makes intent clearer when reading the code.
