import Foundation
#if canImport(FlutterMacOS)
import FlutterMacOS
#else
import Flutter
#endif
// StoreKit is not directly used; relying on OpenIAP
import OpenIAP

@available(iOS 15.0, macOS 14.0, tvOS 15.0, *)
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
    
    // Override local catalog with canonical OpenIAP messages
    private func defaultMessage(for code: ErrorCode) -> String {
        PurchaseError.defaultMessage(for: code)
    }

    private func defaultMessage(for rawCode: String) -> String {
        PurchaseError.defaultMessage(for: rawCode)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        FlutterIapLog.debug("Swift register called")
        #if canImport(FlutterMacOS)
        let channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger)
        #else
        let channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger())
        #endif
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
        FlutterIapLog.debug("Swift handle called with method: \(call.method)")
        
        switch call.method {
        case "canMakePayments":
            FlutterIapLog.debug("canMakePayments called (OpenIAP)")
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
                let code: ErrorCode = .developerError
                result(FlutterError(code: code.rawValue, message: "Invalid params for fetchProducts", details: nil))
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

        case "getActiveSubscriptions":
            if let subscriptionIds = call.arguments as? [String] {
                getActiveSubscriptions(subscriptionIds: subscriptionIds, result: result)
            } else {
                getActiveSubscriptions(subscriptionIds: nil, result: result)
            }
            
        case "requestPurchase":
            // OpenIAP requestPurchase expects structured props
            if let args = call.arguments as? [String: Any] {
                requestPurchase(args: args, result: result)
            } else if let sku = call.arguments as? String {
                requestPurchase(args: ["sku": sku], result: result)
            } else {
                let code: ErrorCode = .developerError
                result(FlutterError(code: code.rawValue, message: "Invalid params for requestPurchase", details: nil))
            }
            
        case "finishTransaction":
            FlutterIapLog.payload("finishTransaction", payload: call.arguments)

            if let args = call.arguments as? [String: Any] {
                if let purchasePayload = args["purchase"] as? [String: Any] {
                    let isConsumable = args["isConsumable"] as? Bool
                    finishTransaction(purchaseDict: purchasePayload, isConsumable: isConsumable, result: result)
                    return
                }
                if let id = args["transactionId"] as? String ?? args["transactionIdentifier"] as? String {
                    FlutterIapLog.debug("finishTransaction extracted transactionId: \(id)")
                    finishTransaction(transactionId: id, result: result)
                    return
                }
            } else if let id = call.arguments as? String {
                FlutterIapLog.debug("finishTransaction using direct transactionId: \(id)")
                finishTransaction(transactionId: id, result: result)
                return
            }

            FlutterIapLog.error("finishTransaction called without transaction info")
            let code: ErrorCode = .developerError
            result(FlutterError(code: code.rawValue, message: "transactionId required", details: nil))
            
        case "getStorefront":
            getStorefront(result: result)

        case "getStorefrontIOS":
            getStorefrontIOS(result: result)

        case "getPendingTransactionsIOS":
            getPendingTransactionsIOS(result: result)

        case "requestPurchaseOnPromotedProductIOS":
            requestPurchaseOnPromotedProductIOS(result: result)

        case "clearTransactionIOS":
            clearTransactionIOS(result: result)

        case "presentCodeRedemptionSheetIOS":
            if #available(iOS 16.0, macOS 14.0, tvOS 16.0, *) {
                presentCodeRedemptionSheetIOS(result: result)
            } else {
                let code: ErrorCode = .featureNotSupported
                result(FlutterError(code: code.rawValue, message: "Code redemption requires iOS 16.0+, macOS 14.0+, or tvOS 16.0+", details: nil))
            }
            
        case "getPromotedProductIOS":
            getPromotedProductIOS(result: result)
            
        case "showManageSubscriptionsIOS":
            showManageSubscriptionsIOS(result: result)

        case "isEligibleForIntroOfferIOS":
            if let args = call.arguments as? [String: Any],
               let groupId = args["productId"] as? String {
                isEligibleForIntroOfferIOS(groupId: groupId, result: result)
            } else {
                let code: ErrorCode = .developerError
                result(FlutterError(code: code.rawValue, message: "productId required", details: nil))
            }

        case "validateReceiptIOS":
            guard let args = call.arguments as? [String: Any] else {
                let code: ErrorCode = .developerError
                result(FlutterError(code: code.rawValue, message: "arguments required", details: nil))
                return
            }
            // Support new API: { apple: { sku: "..." } } or legacy { sku: "..." }
            let sku: String
            if let appleOptions = args["apple"] as? [String: Any],
               let appleSku = appleOptions["sku"] as? String {
                sku = appleSku
            } else if let legacySku = args["sku"] as? String {
                // Backwards compatibility with legacy API
                sku = legacySku
            } else {
                let code: ErrorCode = .developerError
                result(FlutterError(code: code.rawValue, message: "apple.sku required", details: nil))
                return
            }
            validateReceiptIOS(productId: sku, result: result)

        case "canPresentExternalPurchaseNoticeIOS":
            if #available(iOS 18.2, macOS 14.0, tvOS 18.2, *) {
                canPresentExternalPurchaseNoticeIOS(result: result)
            } else {
                let code: ErrorCode = .featureNotSupported
                result(FlutterError(code: code.rawValue, message: "External purchase notice requires iOS 18.2+, macOS 14.0+, or tvOS 18.2+", details: nil))
            }

        case "presentExternalPurchaseNoticeSheetIOS":
            if #available(iOS 18.2, macOS 14.0, tvOS 18.2, *) {
                presentExternalPurchaseNoticeSheetIOS(result: result)
            } else {
                let code: ErrorCode = .featureNotSupported
                result(FlutterError(code: code.rawValue, message: "External purchase notice requires iOS 18.2+, macOS 14.0+, or tvOS 18.2+", details: nil))
            }

        case "presentExternalPurchaseLinkIOS":
            if #available(iOS 16.0, macOS 14.0, tvOS 16.0, *) {
                if let args = call.arguments as? [String: Any],
                   let url = args["url"] as? String {
                    presentExternalPurchaseLinkIOS(url: url, result: result)
                } else if let url = call.arguments as? String {
                    presentExternalPurchaseLinkIOS(url: url, result: result)
                } else {
                    let code: ErrorCode = .developerError
                    result(FlutterError(code: code.rawValue, message: "url required", details: nil))
                }
            } else {
                let code: ErrorCode = .featureNotSupported
                result(FlutterError(code: code.rawValue, message: "External purchase link requires iOS 16.0+, macOS 14.0+, or tvOS 16.0+", details: nil))
            }

        case "verifyPurchaseWithProvider":
            guard let args = call.arguments as? [String: Any],
                  let providerStr = args["provider"] as? String else {
                let code: ErrorCode = .developerError
                result(FlutterError(code: code.rawValue, message: "provider required", details: nil))
                return
            }
            verifyPurchaseWithProvider(args: args, provider: providerStr, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Connection Management
    
    private func initConnection(result: @escaping FlutterResult) {
        FlutterIapLog.debug("initConnection called")
        // Ensure listeners are set before initializing connection (Expo-style)
        setupOpenIapListeners()
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.initConnection()
                result(nil)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .initConnection
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    private func endConnection(result: @escaping FlutterResult) {
        FlutterIapLog.debug("endConnection called")
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
        FlutterIapLog.debug("Setting up OpenIAP listeners")

        purchaseUpdatedToken = OpenIapModule.shared.purchaseUpdatedListener { [weak self] purchase in
            Task { @MainActor in
                guard let self else { return }
                FlutterIapLog.debug("purchaseUpdatedListener fired for \(purchase.productId)")
                let payload = FlutterIapHelper.sanitizeDictionary(OpenIapSerialization.purchase(purchase))
                if let jsonString = FlutterIapHelper.jsonString(from: payload) {
                    self.channel?.invokeMethod("purchase-updated", arguments: jsonString)
                }
            }
        }

        purchaseErrorToken = OpenIapModule.shared.purchaseErrorListener { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                FlutterIapLog.debug("purchaseErrorListener fired")
                let _ : [String: Any?] = [
                    "code": error.code.rawValue,
                    "message": error.message,
                    "productId": error.productId
                ]
                let compacted = FlutterIapHelper.sanitizeDictionary([
                    "code": error.code.rawValue,
                    "message": error.message,
                    "productId": error.productId
                ])
                if let jsonString = FlutterIapHelper.jsonString(from: compacted) {
                    self.channel?.invokeMethod("purchase-error", arguments: jsonString)
                }
            }
        }
        
        promotedProductToken = OpenIapModule.shared.promotedProductListenerIOS { [weak self] productId in
            Task { @MainActor in
                guard let self = self else { return }
                FlutterIapLog.debug("promotedProductListenerIOS fired for: \(productId)")
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
    
    // All transaction event handling is routed via OpenIapModule listeners
    
    // No direct StoreKit transaction state evaluation; handled by OpenIAP
    
    enum StoreError: Error {
        case verificationFailed
        case productNotFound
        case purchaseFailed
    }
    
    // MARK: - Product Loading
    
    private func fetchProducts(params: [String: Any], result: @escaping FlutterResult) {
        FlutterIapLog.payload("fetchProducts", payload: params)
        Task { @MainActor in
            do {
                let request = try FlutterIapHelper.decodeProductRequest(from: params)
                let products = try await OpenIapModule.shared.fetchProducts(request)
                let serialized = FlutterIapHelper.sanitizeArray(
                    OpenIapSerialization.products(products, logger: { FlutterIapLog.debug($0) })
                )
                FlutterIapLog.result("fetchProducts", value: serialized)
                result(serialized)
            } catch let purchaseError as PurchaseError {
                FlutterIapLog.failure("fetchProducts", error: purchaseError)
                result(FlutterError(
                    code: purchaseError.code.rawValue,
                    message: purchaseError.message,
                    details: purchaseError.productId
                ))
            } catch {
                FlutterIapLog.failure("fetchProducts", error: error)
                let code: ErrorCode = .queryProduct
                result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: error.localizedDescription))
            }
        }
    }

    // MARK: - Available Items
    
    private func getAvailableItems(
        result: @escaping FlutterResult,
        onlyIncludeActiveItems: Bool = true,
        alsoPublishToEventListener: Bool = false
    ) {
        FlutterIapLog.debug("getAvailableItems called (onlyActive: \(onlyIncludeActiveItems), alsoPublish: \(alsoPublishToEventListener))")
        Task { @MainActor in
            do {
                let opts = try FlutterIapHelper.decodePurchaseOptions(
                    alsoPublish: alsoPublishToEventListener,
                    onlyIncludeActive: onlyIncludeActiveItems
                )
                let purchases = try await OpenIapModule.shared.getAvailablePurchases(opts)
                let serialized = FlutterIapHelper.sanitizeArray(OpenIapSerialization.purchases(purchases))
                FlutterIapLog.result("getAvailableItems", value: serialized)
                await MainActor.run { result(serialized) }
            } catch {
                FlutterIapLog.failure("getAvailableItems", error: error)
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: error.localizedDescription))
                }
            }
        }
    }

    private func getActiveSubscriptions(
        subscriptionIds: [String]?,
        result: @escaping FlutterResult
    ) {
        FlutterIapLog.debug("getActiveSubscriptions called with subscriptionIds: \(String(describing: subscriptionIds))")
        Task { @MainActor in
            do {
                let subscriptions = try await OpenIapModule.shared.getActiveSubscriptions(subscriptionIds)
                let serialized = subscriptions.map { OpenIapSerialization.encode($0) }
                let sanitized = FlutterIapHelper.sanitizeArray(serialized)
                FlutterIapLog.result("getActiveSubscriptions", value: sanitized)
                await MainActor.run { result(sanitized) }
            } catch {
                FlutterIapLog.failure("getActiveSubscriptions", error: error)
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: error.localizedDescription))
                }
            }
        }
    }
    
    // MARK: - Purchase
    private func requestPurchase(args: [String: Any], result: @escaping FlutterResult) {
        let sku = (args["sku"] as? String) ?? (args["productId"] as? String)
        guard let sku else {
            let code: ErrorCode = .developerError
            result(FlutterError(code: code.rawValue, message: "sku required", details: nil))
            return
        }
        FlutterIapLog.payload("requestPurchase", payload: args)

        Task { @MainActor in
            do {
                let props = try FlutterIapHelper.decodeRequestPurchaseProps(from: args)
                _ = try await OpenIapModule.shared.requestPurchase(props)
                FlutterIapLog.info("requestPurchase dispatched successfully for sku \(sku)")
                result(nil)
            } catch let purchaseError as PurchaseError {
                FlutterIapLog.failure("requestPurchase", error: purchaseError)
                result(FlutterError(
                    code: purchaseError.code.rawValue,
                    message: purchaseError.message,
                    details: purchaseError.productId ?? sku
                ))
            } catch {
                FlutterIapLog.failure("requestPurchase", error: error)
                let code: ErrorCode = .purchaseError
                result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: error.localizedDescription))
            }
        }
    }
    
    // MARK: - Transaction Management
    
    private func finishTransaction(purchaseDict: [String: Any], isConsumable: Bool?, result: @escaping FlutterResult) {
        FlutterIapLog.payload("finishTransaction", payload: [
            "purchase": purchaseDict,
            "isConsumable": isConsumable as Any
        ])
        Task { @MainActor in
            do {
                let purchase = try FlutterIapHelper.decodePurchaseInput(from: purchaseDict)
                try await OpenIapModule.shared.finishTransaction(purchase: purchase, isConsumable: isConsumable)
                FlutterIapLog.result("finishTransaction", value: true)
                result(nil)
            } catch {
                FlutterIapLog.failure("finishTransaction", error: error)
                if let idValue = purchaseDict["id"] as? String, !idValue.isEmpty {
                    finishTransaction(transactionId: idValue, result: result)
                    return
                }
                let code: ErrorCode = .serviceError
                result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: error.localizedDescription))
            }
        }
    }

    private func finishTransaction(transactionId: String, result: @escaping FlutterResult) {
        FlutterIapLog.debug("finishTransaction fallback with transactionId: \(transactionId)")
        Task { @MainActor in
            do {
                let fallback = try FlutterIapHelper.fallbackPurchaseInput(for: transactionId)
                try await OpenIapModule.shared.finishTransaction(purchase: fallback, isConsumable: nil)
                result(nil)
            } catch {
                FlutterIapLog.failure("finishTransactionFallback", error: error)
                let code: ErrorCode = .serviceError
                result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: error.localizedDescription))
            }
        }
    }
    
    // MARK: - Additional iOS Features

    // (Moved below iOS-specific features section to align with Expo ordering)
    @available(iOS 16.0, macOS 14.0, tvOS 16.0, *)
    private func presentCodeRedemptionSheetIOS(result: @escaping FlutterResult) {
        FlutterIapLog.debug("presentCodeRedemptionSheetIOS called")
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.presentCodeRedemptionSheetIOS()
                FlutterIapLog.result("presentCodeRedemptionSheetIOS", value: true)
                result(nil)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    @available(iOS 15.0, macOS 14.0, tvOS 15.0, *)
    private func showManageSubscriptionsIOS(result: @escaping FlutterResult) {
        FlutterIapLog.debug("showManageSubscriptionsIOS called")
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.showManageSubscriptionsIOS()
                FlutterIapLog.result("showManageSubscriptionsIOS", value: true)
                result(nil)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .activityUnavailable
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    private func requestPurchaseOnPromotedProductIOS(result: @escaping FlutterResult) {
        FlutterIapLog.debug("requestPurchaseOnPromotedProductIOS called")
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.requestPurchaseOnPromotedProductIOS()
                FlutterIapLog.result("requestPurchaseOnPromotedProductIOS", value: true)
                result(nil)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    private func getPromotedProductIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                if let promoted = try await OpenIapModule.shared.getPromotedProductIOS() {
                    let serialized = FlutterIapHelper.sanitizeDictionary(OpenIapSerialization.encode(promoted))
                    FlutterIapLog.result("getPromotedProductIOS", value: serialized)
                    result(serialized)
                } else {
                    FlutterIapLog.info("No promoted product available")
                    result(nil)
                }
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    private func getStorefront(result: @escaping FlutterResult) {
        FlutterIapLog.debug("getStorefront called")
        Task { @MainActor in
            do {
                let code = try await OpenIapModule.shared.getStorefrontIOS()
                FlutterIapLog.result("getStorefront", value: code)
                result(code)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }

    private func getStorefrontIOS(result: @escaping FlutterResult) {
        FlutterIapLog.debug("getStorefrontIOS called")
        Task { @MainActor in
            do {
                let code = try await OpenIapModule.shared.getStorefrontIOS()
                FlutterIapLog.result("getStorefrontIOS", value: ["countryCode": code])
                result(["countryCode": code])
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    private func getPendingTransactionsIOS(result: @escaping FlutterResult) {
        Task { @MainActor in
            do {
                let pending = try await OpenIapModule.shared.getPendingTransactionsIOS()
                let purchases = pending.map { Purchase.purchaseIos($0) }
                let serialized = FlutterIapHelper.sanitizeArray(OpenIapSerialization.purchases(purchases))
                FlutterIapLog.result("getPendingTransactionsIOS", value: serialized)
                result(serialized)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    private func clearTransactionIOS(result: @escaping FlutterResult) {
        FlutterIapLog.debug("clearTransactionIOS called")
        Task { @MainActor in
            do {
                _ = try await OpenIapModule.shared.clearTransactionIOS()
                FlutterIapLog.result("clearTransactionIOS", value: true)
                result(nil)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func isEligibleForIntroOfferIOS(groupId: String, result: @escaping FlutterResult) {
        FlutterIapLog.payload("isEligibleForIntroOfferIOS", payload: ["groupID": groupId])
        Task { @MainActor in
            do {
                let eligible = try await OpenIapModule.shared.isEligibleForIntroOfferIOS(groupID: groupId)
                FlutterIapLog.result("isEligibleForIntroOfferIOS", value: eligible)
                result(eligible)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }

    // MARK: - Receipt Validation (OpenIAP)

    private func validateReceiptIOS(productId: String, result: @escaping FlutterResult) {
        FlutterIapLog.debug("validateReceiptIOS called for product: \(productId)")
        Task { @MainActor in
            do {
                let props = try FlutterIapHelper.decodeVerifyPurchaseProps(for: productId)
                let res = try await OpenIapModule.shared.validateReceiptIOS(props)
                var payload: [String: Any?] = [
                    "isValid": res.isValid,
                    "receiptData": res.receiptData,
                    // Provide both fields for compatibility with OpenIAP spec and legacy
                    "jwsRepresentation": res.jwsRepresentation,
                    "purchaseToken": res.jwsRepresentation,
                    "platform": "ios"
                ]
                if let latest = res.latestTransaction {
                    payload["latestTransaction"] = FlutterIapHelper.sanitizeDictionary(OpenIapSerialization.purchase(latest))
                }
                FlutterIapLog.result("validateReceiptIOS", value: payload)
                await MainActor.run { result(payload) }
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .transactionValidationFailed
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }

    // MARK: - Verify Purchase with Provider (IAPKit)

    private func verifyPurchaseWithProvider(args: [String: Any], provider: String, result: @escaping FlutterResult) {
        FlutterIapLog.debug("verifyPurchaseWithProvider called with provider: \(provider)")
        Task { @MainActor in
            do {
                // Build props dictionary for OpenIAP
                var propsDict: [String: Any] = ["provider": provider]
                if let iapkit = args["iapkit"] as? [String: Any] {
                    var iapkitDict: [String: Any] = [:]
                    if let apiKey = iapkit["apiKey"] as? String {
                        iapkitDict["apiKey"] = apiKey
                    }
                    if let jws = (iapkit["apple"] as? [String: Any])?["jws"] as? String {
                        iapkitDict["apple"] = ["jws": jws]
                    }
                    if let purchaseToken = (iapkit["google"] as? [String: Any])?["purchaseToken"] as? String {
                        iapkitDict["google"] = ["purchaseToken": purchaseToken]
                    }
                    propsDict["iapkit"] = iapkitDict
                }

                // Use JSONSerialization + JSONDecoder
                let jsonData = try JSONSerialization.data(withJSONObject: propsDict)
                let props = try JSONDecoder().decode(VerifyPurchaseWithProviderProps.self, from: jsonData)
                let res = try await OpenIapModule.shared.verifyPurchaseWithProvider(props)

                // Convert result to dictionary
                var payload: [String: Any] = [
                    "provider": res.provider.rawValue
                ]
                if let iapkitItem = res.iapkit {
                    payload["iapkit"] = [
                        "isValid": iapkitItem.isValid,
                        "state": iapkitItem.state.rawValue,
                        "store": iapkitItem.store.rawValue
                    ]
                }
                FlutterIapLog.result("verifyPurchaseWithProvider", value: payload)
                result(payload)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .purchaseVerificationFailed
                    result(FlutterError(code: code.rawValue, message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    // MARK: - Alternative Billing (iOS 18.2+)

    @available(iOS 18.2, macOS 14.0, tvOS 18.2, *)
    private func canPresentExternalPurchaseNoticeIOS(result: @escaping FlutterResult) {
        FlutterIapLog.debug("canPresentExternalPurchaseNoticeIOS called")
        Task { @MainActor in
            do {
                let canPresent = try await OpenIapModule.shared.canPresentExternalPurchaseNoticeIOS()
                FlutterIapLog.result("canPresentExternalPurchaseNoticeIOS", value: canPresent)
                result(canPresent)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }

    @available(iOS 18.2, macOS 14.0, tvOS 18.2, *)
    private func presentExternalPurchaseNoticeSheetIOS(result: @escaping FlutterResult) {
        FlutterIapLog.debug("presentExternalPurchaseNoticeSheetIOS called")
        Task { @MainActor in
            do {
                let res = try await OpenIapModule.shared.presentExternalPurchaseNoticeSheetIOS()
                let payload = FlutterIapHelper.sanitizeDictionary(OpenIapSerialization.encode(res))
                FlutterIapLog.result("presentExternalPurchaseNoticeSheetIOS", value: payload)
                result(payload)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }

    @available(iOS 16.0, macOS 14.0, tvOS 16.0, *)
    private func presentExternalPurchaseLinkIOS(url: String, result: @escaping FlutterResult) {
        FlutterIapLog.debug("presentExternalPurchaseLinkIOS called with url: \(url)")
        Task { @MainActor in
            do {
                let res = try await OpenIapModule.shared.presentExternalPurchaseLinkIOS(url)
                let payload = FlutterIapHelper.sanitizeDictionary(OpenIapSerialization.encode(res))
                FlutterIapLog.result("presentExternalPurchaseLinkIOS", value: payload)
                result(payload)
            } catch {
                await MainActor.run {
                    let code: ErrorCode = .serviceError
                    result(FlutterError(code: code.rawValue, message: defaultMessage(for: code), details: nil))
                }
            }
        }
    }
    
    
    
    // clearTransactionCache removed (no-op)
    
    // MARK: - Helpers
    
    // No StoreKit product/period type mapping needed; OpenIAP provides serialization
}


// Fallback for platforms that don't meet minimum requirements
public class FlutterInappPurchasePluginLegacy: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        if #unavailable(iOS 15.0, macOS 14.0, tvOS 15.0) {
            #if canImport(FlutterMacOS)
            let channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger)
            #else
            let channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger())
            #endif
            let instance = FlutterInappPurchasePluginLegacy()
            registrar.addMethodCallDelegate(instance, channel: channel)
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let code: ErrorCode = .featureNotSupported
        result(FlutterError(code: code.rawValue, message: "iOS 15.0+, macOS 14.0+, or tvOS 15.0+ required", details: nil))
    }
}
