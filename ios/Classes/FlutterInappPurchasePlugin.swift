import Foundation
import Flutter
// StoreKit is not directly used; relying on OpenIAP
import OpenIAP

@available(iOS 15.0, *)
@MainActor
public class FlutterInappPurchasePlugin: NSObject, FlutterPlugin {
    private static let TAG = "[FlutterInappPurchase]"
    private var channel: FlutterMethodChannel?
    private var updateListenerTask: Task<Void, Never>?
    // OpenIAP listener tokens
    private var purchaseUpdatedToken: OpenIAP.Subscription?
    private var purchaseErrorToken: OpenIAP.Subscription?
    private var promotedProductToken: OpenIAP.Subscription?
    // No local StoreKit caches; OpenIAP handles state internally
    private var processedTransactionIds: Set<String> = []
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("\(TAG) Swift register called")
        if #available(iOS 15.0, *) {
            let channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger())
            let instance = FlutterInappPurchasePlugin()
            registrar.addMethodCallDelegate(instance, channel: channel)
            instance.channel = channel
            // Set up OpenIAP listeners as early as possible (Expo-style)
            instance.setupOpenIapListeners()
        } else {
            print("\(TAG) iOS 15.0+ required for StoreKit 2")
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) Swift handle called with method: '\(call.method)' and arguments: \(String(describing: call.arguments))")
        
        switch call.method {
        case "canMakePayments":
            print("\(FlutterInappPurchasePlugin.TAG) canMakePayments called (OpenIAP)")
            // OpenIAP abstraction: assume payments can be made once initialized
            result(true)
            
        case "initConnection":
            initConnection(result: result)
            
        case "endConnection":
            endConnection(result: result)
            
        case "fetchProducts":
            // OpenIAP-compliant: accepts { skus: [String], type: 'inapp'|'subs'|'all' }
            if let args = call.arguments as? [String: Any] {
                fetchProducts(params: args, result: result)
            } else if let skus = call.arguments as? [String] {
                let params: [String: Any] = ["skus": skus, "type": "all"]
                fetchProducts(params: params, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid params for fetchProducts", details: nil))
            }
            
        case "getAvailableItems":
            if let args = call.arguments as? [String: Any] {
                let onlyIncludeActiveItems = args["onlyIncludeActiveItemsIOS"] as? Bool ?? true
                let alsoPublishToEventListener = args["alsoPublishToEventListenerIOS"] as? Bool ?? false
                getAvailableItems(
                    result: result, 
                    onlyIncludeActiveItems: onlyIncludeActiveItems,
                    alsoPublishToEventListener: alsoPublishToEventListener
                )
            } else {
                getAvailableItems(result: result)
            }
            
        case "buyProduct":
            // Support both old and new API
            var productId: String?
            
            if let args = call.arguments as? [String: Any] {
                productId = args["productId"] as? String ?? args["sku"] as? String
            } else if let id = call.arguments as? String {
                productId = id
            }
            
            guard let id = productId else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "productId required", details: nil))
                return
            }
            buyProduct(productId: id, result: result)
            
        case "finishTransaction":
            // Support both old and new API
            var transactionId: String?
            
            print("\(FlutterInappPurchasePlugin.TAG) finishTransaction called with arguments: \(String(describing: call.arguments))")
            
            if let args = call.arguments as? [String: Any] {
                transactionId = args["transactionId"] as? String ?? args["transactionIdentifier"] as? String
                print("\(FlutterInappPurchasePlugin.TAG) Extracted transactionId from args: \(transactionId ?? "nil")")
            } else if let id = call.arguments as? String {
                transactionId = id
                print("\(FlutterInappPurchasePlugin.TAG) Using direct string as transactionId: \(id)")
            }
            
            guard let id = transactionId else {
                print("\(FlutterInappPurchasePlugin.TAG) ERROR: No transactionId found in arguments")
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "transactionId required", details: nil))
                return
            }
            print("\(FlutterInappPurchasePlugin.TAG) Final transactionId to finish: \(id)")
            finishTransaction(transactionId: id, result: result)
            
        case "getStorefrontIOS":
            getStorefrontIOS(result: result)

        case "getPendingTransactionsIOS":
            getPendingTransactionsIOS(result: result)

        case "requestPurchaseOnPromotedProductIOS":
            requestPurchaseOnPromotedProductIOS(result: result)

        case "clearTransactionIOS":
            clearTransactionIOS(result: result)

        case "presentCodeRedemptionSheetIOS":
            if #available(iOS 16.0, *) {
                presentCodeRedemptionSheetIOS(result: result)
            } else {
                result(FlutterError(code: "UNSUPPORTED", message: "Code redemption requires iOS 16.0+", details: nil))
            }
            
        case "getPromotedProductIOS":
            getPromotedProductIOS(result: result)
            
        case "showManageSubscriptionsIOS":
            showManageSubscriptionsIOS(result: result)
            
        case "clearTransactionCache":
            // No-op on iOS/OpenIAP to avoid spurious exceptions from Dart side
            result(nil)
            
        case "validateReceiptIOS":
            guard let args = call.arguments as? [String: Any],
                  let sku = args["sku"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "sku required", details: nil))
                return
            }
            validateReceiptIOS(productId: sku, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Connection Management
    
    private func initConnection(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) initConnection called")
        // Ensure listeners are set before initializing connection (Expo-style)
        setupOpenIapListeners()
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.initConnection()
                result(nil)
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_INIT_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func endConnection(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) endConnection called")
        removeOpenIapListeners()
        Task {
            _ = try? await OpenIapModule.shared.endConnection()
            result(nil)
        }
    }

    private func cleanupExistingState() {
        updateListenerTask?.cancel()
        updateListenerTask = nil
        processedTransactionIds.removeAll()
        removeOpenIapListeners()
    }
    
    // MARK: - OpenIAP Listeners
    private func setupOpenIapListeners() {
        if purchaseUpdatedToken != nil || purchaseErrorToken != nil { return }
        print("\(FlutterInappPurchasePlugin.TAG) Setting up OpenIAP listeners")
        
        purchaseUpdatedToken = OpenIapModule.shared.purchaseUpdatedListener { [weak self] purchase in
            Task { @MainActor in
                guard let self = self else { return }
                print("\(FlutterInappPurchasePlugin.TAG) ✅ purchaseUpdatedListener fired")
                let payload = OpenIapSerialization.purchase(purchase)
                var sanitized = self.sanitize(dict: payload)
                // Coerce iOS fields that Dart expects as String
                if let n = sanitized["webOrderLineItemIdIOS"] as? NSNumber { sanitized["webOrderLineItemIdIOS"] = n.stringValue }
                if let n = sanitized["originalTransactionIdentifierIOS"] as? NSNumber { sanitized["originalTransactionIdentifierIOS"] = n.stringValue }
                if let n = sanitized["subscriptionGroupIdIOS"] as? NSNumber { sanitized["subscriptionGroupIdIOS"] = n.stringValue }
                if let n = sanitized["reasonIOS"] as? NSNumber { sanitized["reasonIOS"] = n.stringValue }
                if let jsonData = try? JSONSerialization.data(withJSONObject: sanitized),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("\(FlutterInappPurchasePlugin.TAG) Emitting purchase-updated to Flutter")
                    self.channel?.invokeMethod("purchase-updated", arguments: jsonString)
                }
            }
        }
        
        purchaseErrorToken = OpenIapModule.shared.purchaseErrorListener { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                print("\(FlutterInappPurchasePlugin.TAG) ❌ purchaseErrorListener fired")
                let errorData: [String: Any?] = [
                    "code": error.code,
                    "message": error.message,
                    "productId": error.productId
                ]
                let sanitized = self.sanitize(dict: errorData)
                if let jsonData = try? JSONSerialization.data(withJSONObject: sanitized),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("\(FlutterInappPurchasePlugin.TAG) Emitting purchase-error to Flutter")
                    self.channel?.invokeMethod("purchase-error", arguments: jsonString)
                }
            }
        }
        
        promotedProductToken = OpenIapModule.shared.promotedProductListenerIOS { [weak self] productId in
            Task { @MainActor in
                guard let self = self else { return }
                print("\(FlutterInappPurchasePlugin.TAG) 📱 promotedProductListenerIOS fired for: \(productId)")
                let payload: [String: Any] = ["productId": productId]
                // Emit event that Dart expects: name 'iap-promoted-product' with String payload
                self.channel?.invokeMethod("iap-promoted-product", arguments: productId)
            }
        }
    }
    
    private func removeOpenIapListeners() {
        if let token = purchaseUpdatedToken { OpenIapModule.shared.removeListener(token) }
        if let token = purchaseErrorToken { OpenIapModule.shared.removeListener(token) }
        if let token = promotedProductToken { OpenIapModule.shared.removeListener(token) }
        purchaseUpdatedToken = nil
        purchaseErrorToken = nil
        promotedProductToken = nil
    }
    
    private func sanitize(dict: [String: Any?]) -> [String: Any] {
        var sanitized: [String: Any] = [:]
        for (k, v) in dict { sanitized[k] = v ?? NSNull() }
        return sanitized
    }
    
    // All transaction event handling is routed via OpenIapModule listeners
    
    // No direct StoreKit transaction state evaluation; handled by OpenIAP
    
    enum StoreError: Error {
        case verificationFailed
        case productNotFound
        case purchaseFailed
    }
    
    // MARK: - Product Loading
    
    private func fetchProducts(params: [String: Any], result: @escaping FlutterResult) {
        let rawSkus = params["skus"] as? [String]
        // Support alternative array format (0,1,2 indexes)
        var skus = rawSkus ?? []
        if skus.isEmpty {
            var temp: [String] = []
            var i = 0
            while let sku = params["\(i)"] as? String { temp.append(sku); i += 1 }
            skus = temp
        }
        let typeStr = (params["type"] as? String) ?? "all"
        print("\(FlutterInappPurchasePlugin.TAG) fetchProducts called with skus: \(skus), type: \(typeStr)")
        guard !skus.isEmpty else {
            result(FlutterError(code: "E_PRODUCT_LOAD_FAILED", message: "Empty SKU list provided", details: nil))
            return
        }
        Task { @MainActor in
            do {
                let reqType: OpenIapRequestProductType = {
                    switch typeStr.lowercased() {
                    case "inapp": return .inapp
                    case "subs": return .subs
                    default: return .all
                    }
                }()
                let request = OpenIapProductRequest(skus: skus, type: reqType)
                let products: [OpenIapProduct] = try await OpenIapModule.shared.fetchProducts(request)
                let serialized = OpenIapSerialization.products(products)
                result(serialized)
            } catch {
                result(FlutterError(code: "E_PRODUCT_LOAD_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    // MARK: - Available Items
    
    private func getAvailableItems(
        result: @escaping FlutterResult,
        onlyIncludeActiveItems: Bool = true,
        alsoPublishToEventListener: Bool = false
    ) {
        print("\(FlutterInappPurchasePlugin.TAG) getAvailableItems called with onlyIncludeActiveItems: \(onlyIncludeActiveItems), alsoPublishToEventListener: \(alsoPublishToEventListener)")
        Task { @MainActor in
            do {
                let opts = OpenIapGetAvailablePurchasesProps(
                    alsoPublishToEventListenerIOS: alsoPublishToEventListener,
                    onlyIncludeActiveItemsIOS: onlyIncludeActiveItems
                )
                let purchases = try await OpenIapModule.shared.getAvailablePurchases(opts)
                let serialized = OpenIapSerialization.purchases(purchases)
                let sanitized = serialized.map { item -> [String: Any] in
                    var dict = self.sanitize(dict: item)
                    // Coerce iOS fields that Dart expects as String (avoid int→String? cast errors)
                    let stringKeys = [
                        "webOrderLineItemIdIOS",
                        "originalTransactionIdentifierIOS",
                        "subscriptionGroupIdIOS",
                        "reasonIOS",
                        "storefrontCountryCodeIOS",
                        "appBundleIdIOS",
                        "ownershipTypeIOS",
                        "productTypeIOS",
                        "currencyIOS",
                    ]
                    for key in stringKeys {
                        if let n = dict[key] as? NSNumber { dict[key] = n.stringValue }
                    }
                    // Ensure id/transactionId are strings if present
                    if let n = dict["id"] as? NSNumber { dict["id"] = n.stringValue }
                    if let n = dict["transactionId"] as? NSNumber { dict["transactionId"] = n.stringValue }
                    return dict
                }
                await MainActor.run { result(sanitized) }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_GET_AVAILABLE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Purchase
    
    private func buyProduct(productId: String, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) buyProduct called with productId: \(productId)")
        Task { @MainActor in
            do {
                let props = OpenIapRequestPurchaseProps(
                    sku: productId,
                    andDangerouslyFinishTransactionAutomatically: false,
                    appAccountToken: nil,
                    quantity: nil,
                    withOffer: nil
                )
                _ = try await OpenIapModule.shared.requestPurchase(props)
                result(nil)
            } catch {
                let errorData: [String: Any] = [
                    "code": "E_PURCHASE_FAILED",
                    "message": error.localizedDescription,
                    "productId": productId
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: errorData),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    channel?.invokeMethod("purchase-error", arguments: jsonString)
                }
                result(FlutterError(code: "E_PURCHASE_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    // MARK: - Transaction Management
    
    private func finishTransaction(transactionId: String, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) finishTransaction called with transactionId: '\(transactionId)'")
        
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.finishTransaction(transactionIdentifier: transactionId)
                result(nil)
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_FINISH_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Additional iOS Features
    
    private func getStorefrontIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                let code = try await OpenIapModule.shared.getStorefrontIOS()
                result(["countryCode": code])
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_STORE_FRONT_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func getPendingTransactionsIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                let pending = try await OpenIapModule.shared.getPendingTransactionsIOS()
                let serialized = OpenIapSerialization.purchases(pending)
                let sanitized = serialized.map { self.sanitize(dict: $0) }
                result(sanitized)
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_PENDING_TX_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func requestPurchaseOnPromotedProductIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                try await OpenIapModule.shared.requestPurchaseOnPromotedProductIOS()
                result(nil)
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_PROMOTED_PURCHASE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func clearTransactionIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                try await OpenIapModule.shared.clearTransactionIOS()
                result(nil)
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_CLEAR_TX_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    @available(iOS 16.0, *)
    private func presentCodeRedemptionSheetIOS(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) presentCodeRedemptionSheet called")
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.presentCodeRedemptionSheetIOS()
                result(nil)
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_REDEEM_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Receipt Validation (OpenIAP)
    
    // Helper function to process transaction and avoid code duplication
    // No direct StoreKit verification; validation is via OpenIAP
    
    private func validateReceiptIOS(productId: String, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) validateReceiptIOS called for product: \(productId)")
        Task { @MainActor in
            do {
                let props = OpenIapReceiptValidationProps(sku: productId)
                let res = try await OpenIapModule.shared.validateReceiptIOS(props)
                var payload: [String: Any] = [
                    "isValid": res.isValid,
                    "receiptData": res.receiptData,
                    // Provide both fields for compatibility with OpenIAP spec and legacy
                    "jwsRepresentation": res.jwsRepresentation,
                    "purchaseToken": res.jwsRepresentation,
                    "platform": "ios"
                ]
                if let latest = res.latestTransaction {
                    payload["latestTransaction"] = sanitize(dict: OpenIapSerialization.purchase(latest))
                }
                await MainActor.run { result(payload) }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_RECEIPT_VALIDATE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func getPromotedProductIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                if let product = try await OpenIapModule.shared.getPromotedProductIOS() {
                    let map: [String: Any] = [
                        "productIdentifier": product.productIdentifier,
                        "localizedTitle": product.localizedTitle,
                        "localizedDescription": product.localizedDescription,
                        "price": product.price,
                        "priceLocale": [
                            "currencyCode": product.priceLocale.currencyCode,
                            "currencySymbol": product.priceLocale.currencySymbol
                        ]
                    ]
                    await MainActor.run { result(map) }
                } else {
                    result(nil)
                }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_PROMOTED_PRODUCT_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func showManageSubscriptionsIOS(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) showManageSubscriptions called")
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.showManageSubscriptionsIOS()
                result(nil)
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_SHOW_SUBSCRIPTIONS_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // clearTransactionCache removed (no-op)
    
    // MARK: - Helpers
    
    // No StoreKit product/period type mapping needed; OpenIAP provides serialization
}

// Fallback for iOS < 15.0
public class FlutterInappPurchasePluginLegacy: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        if #unavailable(iOS 15.0) {
            let channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger())
            let instance = FlutterInappPurchasePluginLegacy()
            registrar.addMethodCallDelegate(instance, channel: channel)
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(code: "UNSUPPORTED", message: "iOS 15.0+ required", details: nil))
    }
}
