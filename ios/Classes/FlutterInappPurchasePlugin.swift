import Foundation
import Flutter
// StoreKit is not directly used; relying on OpenIAP
import OpenIAP

@available(iOS 15.0, *)
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
    
    // Produce standardized message from OpenIAP error catalog
    private func defaultMessage(for code: String) -> String {
        return OpenIapError.defaultMessage(for: code)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("\(TAG) Swift register called")
        let channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger())
        let instance = FlutterInappPurchasePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.channel = channel
        // Set up OpenIAP listeners as early as possible (Expo-style)
        instance.setupOpenIapListeners()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.handleOnMain(call, result: result)
        }
    }

    @MainActor
    private func handleOnMain(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
                result(FlutterError(code: OpenIapError.DeveloperError, message: "Invalid params for fetchProducts", details: nil))
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
            
        case "requestPurchase":
            // OpenIAP requestPurchase expects structured props
            if let args = call.arguments as? [String: Any] {
                requestPurchase(args: args, result: result)
            } else if let sku = call.arguments as? String {
                requestPurchase(args: ["sku": sku], result: result)
            } else {
                result(FlutterError(code: OpenIapError.DeveloperError, message: "Invalid params for requestPurchase", details: nil))
            }
            
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
                result(FlutterError(code: OpenIapError.DeveloperError, message: "transactionId required", details: nil))
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
                result(FlutterError(code: OpenIapError.FeatureNotSupported, message: "Code redemption requires iOS 16.0+", details: nil))
            }
            
        case "getPromotedProductIOS":
            getPromotedProductIOS(result: result)
            
        case "showManageSubscriptionsIOS":
            showManageSubscriptionsIOS(result: result)
            
            
            
        case "validateReceiptIOS":
            guard let args = call.arguments as? [String: Any],
                  let sku = args["sku"] as? String else {
                result(FlutterError(code: OpenIapError.DeveloperError, message: "sku required", details: nil))
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
                    let code = OpenIapError.InitConnection
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
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
            result(FlutterError(code: OpenIapError.QueryProduct, message: "Empty SKU list provided", details: nil))
            return
        }
        Task { @MainActor in
            do {
                let reqType: OpenIapRequestProductType = {
                    switch typeStr.lowercased() {
                    case "inapp": return .inApp
                    case "subs": return .subs
                    default: return .all
                    }
                }()
                let request = OpenIapProductRequest(skus: skus, type: reqType)
                let products: [OpenIapProduct] = try await OpenIapModule.shared.fetchProducts(request)
                let serialized = OpenIapSerialization.products(products)
                result(serialized)
            } catch {
                let code = OpenIapError.QueryProduct
                result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
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
                    let code = OpenIapError.ServiceError
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    // MARK: - Purchase
    private func requestPurchase(args: [String: Any], result: @escaping FlutterResult) {
        let sku = (args["sku"] as? String) ?? (args["productId"] as? String)
        guard let sku else {
            result(FlutterError(code: OpenIapError.DeveloperError, message: "sku required", details: nil))
            return
        }
        let autoFinish = (args["andDangerouslyFinishTransactionAutomatically"] as? Bool) ?? false
        let appAccountToken = args["appAccountToken"] as? String
        let quantity: Int? = {
            if let q = args["quantity"] as? Int { return q }
            if let qs = args["quantity"] as? String, let q = Int(qs) { return q }
            return nil
        }()
        var withOffer: OpenIapDiscountOffer? = nil
        if let offer = args["withOffer"] as? [String: Any] {
            if let id = offer["identifier"] as? String,
               let key = offer["keyIdentifier"] as? String,
               let nonce = offer["nonce"] as? String,
               let sig = offer["signature"] as? String,
               let ts = offer["timestamp"] as? String {
                withOffer = OpenIapDiscountOffer(identifier: id, keyIdentifier: key, nonce: nonce, signature: sig, timestamp: ts)
            }
        }
        print("\(FlutterInappPurchasePlugin.TAG) requestPurchase called with sku: \(sku)")
        Task { @MainActor in
            do {
                let props = OpenIapRequestPurchaseProps(
                    sku: sku,
                    andDangerouslyFinishTransactionAutomatically: autoFinish,
                    appAccountToken: appAccountToken,
                    quantity: quantity,
                    withOffer: withOffer
                )
                _ = try await OpenIapModule.shared.requestPurchase(props)
                result(nil)
            } catch {
                let errorData: [String: Any] = [
                    "code": OpenIapError.PurchaseError,
                    "message": defaultMessage(for: OpenIapError.PurchaseError),
                    "productId": sku
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: errorData),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    channel?.invokeMethod("purchase-error", arguments: jsonString)
                }
                let code = OpenIapError.PurchaseError
                result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
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
                    let code = OpenIapError.ServiceError
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    // MARK: - Additional iOS Features
    
    // (Moved below iOS-specific features section to align with Expo ordering)
    @available(iOS 16.0, *)
    private func presentCodeRedemptionSheetIOS(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) presentCodeRedemptionSheet called")
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.presentCodeRedemptionSheetIOS()
                result(nil)
            } catch {
                await MainActor.run {
                    let code = OpenIapError.ServiceError
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
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
                    let code = OpenIapError.ActivityUnavailable
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
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
                    let code = OpenIapError.ServiceError
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    private func getPromotedProductIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                // Try to get the promoted product identifier first
                if let promoted = try await OpenIapModule.shared.getPromotedProductIOS() {
                    let sku = promoted.productIdentifier
                    // Fetch full OpenIAP product serialization for consistent shape
                    let request = OpenIapProductRequest(skus: [sku], type: .all)
                    let products: [OpenIapProduct] = try await OpenIapModule.shared.fetchProducts(request)
                    let serialized = OpenIapSerialization.products(products)
                    if let first = serialized.first {
                        let sanitized = self.sanitize(dict: first)
                        result(sanitized)
                    } else {
                        result(nil)
                    }
                } else {
                    result(nil)
                }
            } catch {
                await MainActor.run {
                    let code = OpenIapError.ServiceError
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    private func getStorefrontIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                let code = try await OpenIapModule.shared.getStorefrontIOS()
                result(["countryCode": code])
            } catch {
                await MainActor.run {
                    let code = OpenIapError.ServiceError
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
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
                    let code = OpenIapError.ServiceError
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
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
                    result(FlutterError(code: OpenIapError.ServiceError, message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Receipt Validation (OpenIAP)
    
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
                    let code = OpenIapError.TransactionValidationFailed
                    result(FlutterError(code: code, message: defaultMessage(for: code), details: nil))
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
        result(FlutterError(code: OpenIapError.FeatureNotSupported, message: "iOS 15.0+ required", details: nil))
    }
}
