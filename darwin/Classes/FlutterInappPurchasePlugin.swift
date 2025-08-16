import Foundation
import Flutter
import StoreKit

@available(iOS 15.0, *)
public class FlutterInappPurchasePlugin: NSObject, FlutterPlugin {
    private static let TAG = "[FlutterInappPurchase]"
    private var channel: FlutterMethodChannel?
    private var updateListenerTask: Task<Void, Never>?
    private var products: [String: Product] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("\(TAG) Swift register called")
        if #available(iOS 15.0, *) {
            let channel = FlutterMethodChannel(name: "flutter_inapp", binaryMessenger: registrar.messenger())
            let instance = FlutterInappPurchasePlugin()
            registrar.addMethodCallDelegate(instance, channel: channel)
            instance.channel = channel
        } else {
            print("\(TAG) iOS 15.0+ required for StoreKit 2")
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) Swift handle called with method: '\(call.method)' and arguments: \(String(describing: call.arguments))")
        
        switch call.method {
        case "canMakePayments":
            print("\(FlutterInappPurchasePlugin.TAG) canMakePayments called")
            let canMake = AppStore.canMakePayments
            print("\(FlutterInappPurchasePlugin.TAG) canMakePayments result: \(canMake)")
            result(canMake)
            
        case "initConnection":
            initConnection(result: result)
            
        case "canMakePayments":
            print("\(FlutterInappPurchasePlugin.TAG) canMakePayments called")
            let canMake = AppStore.canMakePayments
            print("\(FlutterInappPurchasePlugin.TAG) canMakePayments result: \(canMake)")
            result(canMake)
            
        case "endConnection":
            endConnection(result: result)
            
        case "getItems":
            guard let args = call.arguments as? [String: Any],
                  let skus = args["skus"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "skus required", details: nil))
                return
            }
            getItems(skus: skus, result: result)
            
        case "getAvailableItems":
            getAvailableItems(result: result)
            
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
            
            if let args = call.arguments as? [String: Any] {
                transactionId = args["transactionId"] as? String ?? args["transactionIdentifier"] as? String
            } else if let id = call.arguments as? String {
                transactionId = id
            }
            
            guard let id = transactionId else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "transactionId required", details: nil))
                return
            }
            finishTransaction(transactionId: id, result: result)
            
        case "restorePurchases":
            restorePurchases(result: result)
            
        case "presentCodeRedemptionSheet":
            if #available(iOS 16.0, *) {
                presentCodeRedemptionSheet(result: result)
            } else {
                result(FlutterError(code: "UNSUPPORTED", message: "Code redemption requires iOS 16.0+", details: nil))
            }
            
        case "getPromotedProduct":
            getPromotedProduct(result: result)
            
        case "showManageSubscriptions":
            showManageSubscriptions(result: result)
            
        case "clearTransactionCache":
            clearTransactionCache(result: result)
            
        case "testStoreKit":
            testStoreKit(result: result)
            
        case "getAppTransaction":
            getAppTransaction(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Test Method
    
    private func testStoreKit(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) testStoreKit called - starting diagnostics")
        
        var testResult: [String: Any] = [:]
        
        // Test 1: Can make payments
        let canMakePayments = AppStore.canMakePayments
        testResult["canMakePayments"] = canMakePayments
        print("\(FlutterInappPurchasePlugin.TAG) Can make payments: \(canMakePayments)")
        
        // Test 2: Bundle identifier
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        testResult["bundleIdentifier"] = bundleId
        print("\(FlutterInappPurchasePlugin.TAG) Bundle identifier: \(bundleId)")
        
        // Test 3: Return immediately with basic info
        print("\(FlutterInappPurchasePlugin.TAG) Returning basic diagnostics immediately")
        result(testResult)
        
        // Test 4: Try async operations separately
        Task {
            print("\(FlutterInappPurchasePlugin.TAG) Starting async StoreKit test...")
            
            do {
                // Test with a very small timeout
                let task = Task { () -> Bool in
                    print("\(FlutterInappPurchasePlugin.TAG) Attempting to fetch a single product...")
                    let products = try await Product.products(for: ["dev.hyo.martie.10bulbs"])
                    print("\(FlutterInappPurchasePlugin.TAG) Products fetched: \(products.count)")
                    return true
                }
                
                // Wait for 2 seconds max
                try await Task.sleep(nanoseconds: 2_000_000_000)
                task.cancel()
                print("\(FlutterInappPurchasePlugin.TAG) Async test timed out after 2 seconds")
                
            } catch {
                print("\(FlutterInappPurchasePlugin.TAG) Async test error: \(error)")
            }
        }
    }
    
    // MARK: - Connection Management
    
    private func initConnection(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) initConnection called")
        
        // Start listening for transaction updates
        updateListenerTask?.cancel()
        updateListenerTask = Task.detached {
            for await update in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(update)
                    await self.processTransaction(transaction)
                } catch {
                    print("\(FlutterInappPurchasePlugin.TAG) Transaction verification failed: \(error)")
                }
            }
        }
        
        // Give StoreKit time to initialize
        Task {
            // Small delay to ensure StoreKit is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                result(nil)
            }
        }
    }
    
    private func endConnection(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) endConnection called")
        updateListenerTask?.cancel()
        updateListenerTask = nil
        products.removeAll()
        result(nil)
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    private func processTransaction(_ transaction: Transaction) async {
        var event: [String: Any] = [
            "productId": transaction.productID,
            "transactionId": "\(transaction.id)",
            "transactionDate": transaction.purchaseDate.timeIntervalSince1970 * 1000,
            "transactionReceipt": transaction.jsonRepresentation.base64EncodedString(),
            "platform": "ios",
            "transactionState": getTransactionState(transaction),
            "isUpgraded": transaction.isUpgraded
        ]
        
        if let expirationDate = transaction.expirationDate {
            event["expirationDate"] = expirationDate.timeIntervalSince1970 * 1000
        }
        
        if let revocationDate = transaction.revocationDate {
            event["revocationDate"] = revocationDate.timeIntervalSince1970 * 1000
            event["revocationReason"] = transaction.revocationReason?.rawValue
        }
        
        // Convert to JSON string as expected by Flutter side
        if let jsonData = try? JSONSerialization.data(withJSONObject: event),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            channel?.invokeMethod("purchase-updated", arguments: jsonString)
        }
    }
    
    private func getTransactionState(_ transaction: Transaction) -> String {
        if transaction.revocationDate != nil {
            return "revoked"
        } else if let expirationDate = transaction.expirationDate, expirationDate < Date() {
            return "expired"
        } else {
            return "purchased"
        }
    }
    
    enum StoreError: Error {
        case verificationFailed
        case productNotFound
        case purchaseFailed
    }
    
    // MARK: - Product Loading
    
    private func getItems(skus: [String], result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) getItems called with skus: \(skus)")
        
        Task {
            do {
                print("\(FlutterInappPurchasePlugin.TAG) Fetching products from StoreKit 2...")
                let productIdentifiers = Set(skus)
                print("\(FlutterInappPurchasePlugin.TAG) Product identifiers: \(productIdentifiers)")
                
                // Check if we can make payments first
                guard AppStore.canMakePayments else {
                    print("\(FlutterInappPurchasePlugin.TAG) Cannot make payments on this device")
                    await MainActor.run {
                        result(FlutterError(code: "E_PAYMENTS_DISABLED", message: "Payments are disabled on this device", details: nil))
                    }
                    return
                }
                
                print("\(FlutterInappPurchasePlugin.TAG) Before calling Product.products(for:)...")
                print("\(FlutterInappPurchasePlugin.TAG) Running on: \(UIDevice.current.name) - \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                
                // Try to fetch products
                let storeProducts: [Product]
                
                print("\(FlutterInappPurchasePlugin.TAG) Attempting to fetch products...")
                print("\(FlutterInappPurchasePlugin.TAG) Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
                
                do {
                    storeProducts = try await Product.products(for: productIdentifiers)
                    print("\(FlutterInappPurchasePlugin.TAG) Successfully fetched \(storeProducts.count) products")
                    
                    // Log each product ID that was found
                    for product in storeProducts {
                        print("\(FlutterInappPurchasePlugin.TAG) Found product: \(product.id) - \(product.displayName)")
                    }
                    
                    // Also log which product IDs were NOT found
                    let foundIds = Set(storeProducts.map { $0.id })
                    let notFoundIds = productIdentifiers.subtracting(foundIds)
                    if !notFoundIds.isEmpty {
                        print("\(FlutterInappPurchasePlugin.TAG) Products NOT found: \(notFoundIds)")
                    }
                } catch StoreKitError.userCancelled {
                    print("\(FlutterInappPurchasePlugin.TAG) User cancelled")
                    storeProducts = []
                } catch StoreKitError.notAvailableInStorefront {
                    print("\(FlutterInappPurchasePlugin.TAG) Products not available in current storefront")
                    storeProducts = []
                } catch StoreKitError.notEntitled {
                    print("\(FlutterInappPurchasePlugin.TAG) User not entitled to these products")
                    storeProducts = []
                } catch {
                    print("\(FlutterInappPurchasePlugin.TAG) Failed to fetch products: \(error)")
                    print("\(FlutterInappPurchasePlugin.TAG) Error type: \(type(of: error))")
                    print("\(FlutterInappPurchasePlugin.TAG) Error description: \(error.localizedDescription)")
                    storeProducts = []
                }
                
                print("\(FlutterInappPurchasePlugin.TAG) Received \(storeProducts.count) products from StoreKit 2")
                
                var productList: [[String: Any]] = []
                
                for product in storeProducts {
                    self.products[product.id] = product
                    
                    var productInfo: [String: Any] = [
                        "productId": product.id,
                        "price": "\(product.price)",
                        "currency": product.priceFormatStyle.currencyCode ?? "USD",
                        "localizedPrice": product.displayPrice,
                        "title": product.displayName,
                        "description": product.description,
                        "type": typeToString(product.type),
                        "originalPrice": "\(product.price)",
                        "platform": "ios",
                        "isFamilyShareable": product.isFamilyShareable
                    ]
                    
                    // Add subscription info if available
                    if let subscription = product.subscription {
                        productInfo["subscriptionPeriodUnitIOS"] = unitToString(subscription.subscriptionPeriod.unit)
                        productInfo["subscriptionPeriodNumberIOS"] = "\(subscription.subscriptionPeriod.value)"
                        
                        if let introOffer = subscription.introductoryOffer {
                            productInfo["introductoryPrice"] = introOffer.displayPrice
                            productInfo["introductoryPriceNumberOfPeriodsIOS"] = "\(introOffer.period.value)"
                            productInfo["introductoryPriceSubscriptionPeriodIOS"] = unitToString(introOffer.period.unit)
                        }
                    }
                    
                    productList.append(productInfo)
                }
                
                print("\(FlutterInappPurchasePlugin.TAG) Returning \(productList.count) products to Flutter")
                await MainActor.run {
                    result(productList)
                }
            } catch {
                print("\(FlutterInappPurchasePlugin.TAG) Failed to load products: \(error)")
                await MainActor.run {
                    result(FlutterError(code: "E_PRODUCT_LOAD_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Available Items
    
    private func getAvailableItems(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) getAvailableItems called")
        
        Task {
            var purchases: [[String: Any]] = []
            
            for await verificationResult in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(verificationResult)
                    let purchase: [String: Any] = [
                        "productId": transaction.productID,
                        "transactionId": "\(transaction.id)",
                        "transactionDate": transaction.purchaseDate.timeIntervalSince1970 * 1000,
                        "transactionReceipt": transaction.jsonRepresentation.base64EncodedString(),
                        "platform": "ios"
                    ]
                    purchases.append(purchase)
                } catch {
                    print("\(FlutterInappPurchasePlugin.TAG) Failed to verify transaction: \(error)")
                }
            }
            
            await MainActor.run {
                result(purchases)
            }
        }
    }
    
    // MARK: - Purchase
    
    private func buyProduct(productId: String, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) buyProduct called with productId: \(productId)")
        
        guard let product = products[productId] else {
            result(FlutterError(code: "E_PRODUCT_NOT_FOUND", message: "Product not found. Please call getItems first.", details: nil))
            return
        }
        
        Task {
            do {
                let purchaseResult = try await product.purchase()
                
                switch purchaseResult {
                case .success(let verification):
                    let transaction = try checkVerified(verification)
                    
                    let purchase: [String: Any] = [
                        "productId": transaction.productID,
                        "transactionId": "\(transaction.id)",
                        "transactionDate": transaction.purchaseDate.timeIntervalSince1970 * 1000,
                        "transactionReceipt": transaction.jsonRepresentation.base64EncodedString(),
                        "platform": "ios"
                    ]
                    
                    // Trigger the purchase-updated event
                    await processTransaction(transaction)
                    
                    await transaction.finish()
                    
                    await MainActor.run {
                        result([purchase])
                    }
                    
                case .userCancelled:
                    await MainActor.run {
                        result(FlutterError(code: "E_USER_CANCELLED", message: "User cancelled the purchase", details: nil))
                    }
                    
                case .pending:
                    await MainActor.run {
                        result(FlutterError(code: "E_PENDING", message: "Purchase is pending", details: nil))
                    }
                    
                @unknown default:
                    await MainActor.run {
                        result(FlutterError(code: "E_UNKNOWN", message: "Unknown purchase result", details: nil))
                    }
                }
            } catch {
                print("\(FlutterInappPurchasePlugin.TAG) Purchase failed: \(error)")
                await MainActor.run {
                    result(FlutterError(code: "E_PURCHASE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Transaction Management
    
    private func finishTransaction(transactionId: String, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) finishTransaction called with transactionId: \(transactionId)")
        
        Task {
            var foundTransaction = false
            
            for await verificationResult in Transaction.all {
                do {
                    let transaction = try checkVerified(verificationResult)
                    if "\(transaction.id)" == transactionId {
                        await transaction.finish()
                        foundTransaction = true
                        break
                    }
                } catch {
                    continue
                }
            }
            
            await MainActor.run {
                if foundTransaction {
                    result(nil)
                } else {
                    result(FlutterError(code: "E_TRANSACTION_NOT_FOUND", message: "Transaction not found", details: nil))
                }
            }
        }
    }
    
    // MARK: - Additional StoreKit 2 Features
    
    private func restorePurchases(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) restorePurchases called")
        
        Task {
            do {
                try await AppStore.sync()
                await MainActor.run {
                    result(nil)
                }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_RESTORE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    @available(iOS 16.0, *)
    private func presentCodeRedemptionSheet(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) presentCodeRedemptionSheet called")
        
        Task {
            do {
                if let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
                    await MainActor.run {
                        result(nil)
                    }
                } else {
                    await MainActor.run {
                        result(FlutterError(code: "E_NO_WINDOW_SCENE", message: "No window scene available", details: nil))
                    }
                }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_REDEEM_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func getPromotedProduct(result: @escaping FlutterResult) {
        // StoreKit 2 handles promoted products through App Store Connect configuration
        result(nil)
    }
    
    @available(iOS 15.0, *)
    private func showManageSubscriptions(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) showManageSubscriptions called")
        
        Task {
            do {
                if let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    try await AppStore.showManageSubscriptions(in: windowScene)
                    await MainActor.run {
                        result(nil)
                    }
                } else {
                    await MainActor.run {
                        result(FlutterError(code: "E_NO_WINDOW_SCENE", message: "No window scene available", details: nil))
                    }
                }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "E_SHOW_SUBSCRIPTIONS_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func clearTransactionCache(result: @escaping FlutterResult) {
        products.removeAll()
        result(nil)
    }
    
    // MARK: - Helpers
    
    private func unitToString(_ unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: return "DAY"
        case .week: return "WEEK"
        case .month: return "MONTH"
        case .year: return "YEAR"
        @unknown default: return "UNKNOWN"
        }
    }
    
    private func typeToString(_ type: Product.ProductType) -> String {
        switch type {
        case .consumable: return "consumable"
        case .nonConsumable: return "nonConsumable"
        case .nonRenewable: return "nonRenewable"
        case .autoRenewable: return "autoRenewable"
        default: return "unknown"
        }
    }
    
    // MARK: - App Transaction
    
    private func getAppTransaction(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) getAppTransaction called")
        
        if #available(iOS 16.0, *) {
            Task {
                do {
                    #if compiler(>=5.7)
                    let verificationResult = try await AppTransaction.shared
                    
                    let appTransaction: AppTransaction
                    switch verificationResult {
                    case .verified(let verified):
                        appTransaction = verified
                    case .unverified(_, _):
                        print("\(FlutterInappPurchasePlugin.TAG) App transaction could not be verified")
                        await MainActor.run {
                            result(nil)
                        }
                        return
                    }
                    
                    var resultDict: [String: Any?] = [
                        "bundleID": appTransaction.bundleID,
                        "appVersion": appTransaction.appVersion,
                        "originalAppVersion": appTransaction.originalAppVersion,
                        "originalPurchaseDate": appTransaction.originalPurchaseDate.timeIntervalSince1970 * 1000,
                        "deviceVerification": appTransaction.deviceVerification.base64EncodedString(),
                        "deviceVerificationNonce": appTransaction.deviceVerificationNonce.uuidString,
                        "environment": appTransaction.environment.rawValue,
                        "signedDate": appTransaction.signedDate.timeIntervalSince1970 * 1000,
                        "appID": appTransaction.appID,
                        "appVersionID": appTransaction.appVersionID,
                        "preorderDate": appTransaction.preorderDate.map { $0.timeIntervalSince1970 * 1000 }
                    ]
                    
                    // iOS 18.4+ specific properties
                    if #available(iOS 18.4, *) {
                        resultDict["appTransactionID"] = appTransaction.appTransactionID
                        resultDict["originalPlatform"] = appTransaction.originalPlatform.rawValue
                    }
                    
                    print("\(FlutterInappPurchasePlugin.TAG) getAppTransaction success")
                    await MainActor.run {
                        result(resultDict)
                    }
                    #else
                    print("\(FlutterInappPurchasePlugin.TAG) getAppTransaction requires Xcode 15.0+ with iOS 16.0 SDK for compilation")
                    await MainActor.run {
                        result(FlutterError(
                            code: "E_COMPILER_VERSION",
                            message: "getAppTransaction requires Xcode 15.0+ with iOS 16.0 SDK for compilation",
                            details: nil
                        ))
                    }
                    #endif
                } catch {
                    print("\(FlutterInappPurchasePlugin.TAG) getAppTransaction error: \(error)")
                    await MainActor.run {
                        result(FlutterError(
                            code: "E_APP_TRANSACTION_ERROR",
                            message: "Failed to get app transaction: \(error.localizedDescription)",
                            details: nil
                        ))
                    }
                }
            }
        } else {
            print("\(FlutterInappPurchasePlugin.TAG) getAppTransaction requires iOS 16.0+")
            result(FlutterError(
                code: "E_IOS_VERSION",
                message: "getAppTransaction requires iOS 16.0+",
                details: nil
            ))
        }
    }
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