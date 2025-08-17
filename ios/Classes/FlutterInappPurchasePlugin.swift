import Foundation
import Flutter
import StoreKit

@available(iOS 15.0, *)
@MainActor
public class FlutterInappPurchasePlugin: NSObject, FlutterPlugin {
    private static let TAG = "[FlutterInappPurchase]"
    private var channel: FlutterMethodChannel?
    private var updateListenerTask: Task<Void, Never>?
    private var products: [String: Product] = [:]
    private var processedTransactionIds: Set<String> = []
    
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
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Connection Management
    
    private func initConnection(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) initConnection called")
        
        // Clear any existing state first
        cleanupExistingState()
        
        // Start listening for transaction updates
        updateListenerTask = Task {
            print("\(FlutterInappPurchasePlugin.TAG) Started listening for transaction updates")
            for await update in Transaction.updates {
                print("\(FlutterInappPurchasePlugin.TAG) Received transaction update")
                do {
                    let transaction = try self.checkVerified(update)
                    print("\(FlutterInappPurchasePlugin.TAG) Raw transaction.id: \(transaction.id)")
                    let transactionId = String(transaction.id)
                    print("\(FlutterInappPurchasePlugin.TAG) Transaction verified - ID: '\(transactionId)' for product: '\(transaction.productID)'")
                    
                    // Send purchase-updated event
                    await self.processTransaction(transaction)
                } catch {
                    print("\(FlutterInappPurchasePlugin.TAG) Transaction verification failed: \(error)")
                }
            }
        }
        
        result(nil)
    }
    
    private func endConnection(result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) endConnection called")
        cleanupExistingState()
        result(nil)
    }
    
    private func cleanupExistingState() {
        updateListenerTask?.cancel()
        updateListenerTask = nil
        products.removeAll()
        processedTransactionIds.removeAll()
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private func processTransaction(_ transaction: Transaction) async {
        print("\(FlutterInappPurchasePlugin.TAG) processTransaction - Raw transaction.id: \(transaction.id)")
        print("\(FlutterInappPurchasePlugin.TAG) processTransaction - transaction.originalID: \(transaction.originalID)")
        let transactionId = String(transaction.id)
        print("\(FlutterInappPurchasePlugin.TAG) processTransaction: ID: '\(transactionId)' for product: '\(transaction.productID)'")
        
        // Check if we've already processed this transaction
        if processedTransactionIds.contains(transactionId) {
            print("\(FlutterInappPurchasePlugin.TAG) Transaction '\(transactionId)' already processed, skipping duplicate event")
            return
        }
        processedTransactionIds.insert(transactionId)
        
        var event: [String: Any] = [
            "id": transactionId,  // Add this for OpenIAP compliance
            "productId": transaction.productID,
            "transactionId": transactionId,
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
            print("\(FlutterInappPurchasePlugin.TAG) Sending purchase-updated event to Flutter")
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
                let productIdentifiers = Set(skus)
                let storeProducts = try await Product.products(for: productIdentifiers)
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
                    print("\(FlutterInappPurchasePlugin.TAG) getAvailableItems - Raw transaction.id: \(transaction.id)")
                    let transactionId = String(transaction.id)
                    print("\(FlutterInappPurchasePlugin.TAG) getAvailableItems - String transactionId: '\(transactionId)'")
                    
                    let purchase: [String: Any] = [
                        "id": transactionId,
                        "productId": transaction.productID,
                        "transactionId": transactionId,
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
                    let transactionId = String(transaction.id)
                    print("\(FlutterInappPurchasePlugin.TAG) Purchase successful with ID: '\(transactionId)' for product: '\(transaction.productID)'")
                    
                    // Send purchase-updated event immediately for Sandbox purchases
                    await self.processTransaction(transaction)
                    print("\(FlutterInappPurchasePlugin.TAG) Purchase event sent - waiting for Flutter to call finishTransaction")
                    
                    await MainActor.run {
                        result(nil)
                    }
                    
                case .userCancelled:
                    print("\(FlutterInappPurchasePlugin.TAG) User cancelled the purchase")
                    // Send purchase-error event like expo-iap
                    let errorData: [String: Any] = [
                        "code": "E_USER_CANCELLED",
                        "message": "User cancelled the purchase",
                        "productId": productId
                    ]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: errorData),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        channel?.invokeMethod("purchase-error", arguments: jsonString)
                    }
                    await MainActor.run {
                        result(FlutterError(code: "E_USER_CANCELLED", message: "User cancelled the purchase", details: nil))
                    }
                    
                case .pending:
                    print("\(FlutterInappPurchasePlugin.TAG) Purchase is pending")
                    // Send purchase-error event like expo-iap
                    let errorData: [String: Any] = [
                        "code": "E_DEFERRED_PAYMENT",
                        "message": "Purchase is pending",
                        "productId": productId
                    ]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: errorData),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        channel?.invokeMethod("purchase-error", arguments: jsonString)
                    }
                    await MainActor.run {
                        result(FlutterError(code: "E_PENDING", message: "Purchase is pending", details: nil))
                    }
                    
                @unknown default:
                    print("\(FlutterInappPurchasePlugin.TAG) Unknown purchase result")
                    // Send purchase-error event like expo-iap
                    let errorData: [String: Any] = [
                        "code": "E_UNKNOWN",
                        "message": "Unknown purchase result",
                        "productId": productId
                    ]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: errorData),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        channel?.invokeMethod("purchase-error", arguments: jsonString)
                    }
                    await MainActor.run {
                        result(FlutterError(code: "E_UNKNOWN", message: "Unknown purchase result", details: nil))
                    }
                }
            } catch {
                print("\(FlutterInappPurchasePlugin.TAG) Purchase failed: \(error)")
                // Send purchase-error event like expo-iap
                let errorData: [String: Any] = [
                    "code": "E_PURCHASE_FAILED",
                    "message": error.localizedDescription,
                    "productId": productId
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: errorData),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    channel?.invokeMethod("purchase-error", arguments: jsonString)
                }
                await MainActor.run {
                    result(FlutterError(code: "E_PURCHASE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    // MARK: - Transaction Management
    
    private func finishTransaction(transactionId: String, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) finishTransaction called with transactionId: '\(transactionId)'")
        
        Task {
            // Try to find and finish the transaction in unfinished transactions
            for await verificationResult in Transaction.unfinished {
                do {
                    let transaction = try checkVerified(verificationResult)
                    let currentTransactionId = String(transaction.id)
                    
                    if currentTransactionId == transactionId {
                        print("\(FlutterInappPurchasePlugin.TAG) Found unfinished transaction! Finishing...")
                        await transaction.finish()
                        print("\(FlutterInappPurchasePlugin.TAG) Transaction finished successfully")
                        
                        await MainActor.run {
                            result(nil)
                        }
                        return
                    }
                } catch {
                    continue
                }
            }
            
            // Transaction not found or already finished - both are success cases
            print("\(FlutterInappPurchasePlugin.TAG) Transaction '\(transactionId)' not found in unfinished - likely already finished")
            await MainActor.run {
                result(nil) // Always return success
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
        // No cache to clear anymore
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