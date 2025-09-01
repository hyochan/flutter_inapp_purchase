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
                    
                    // Send purchase-updated event with JWS
                    await self.processTransaction(transaction, jwsRepresentation: update.jwsRepresentation)
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
    
    private func processTransaction(_ transaction: Transaction, jwsRepresentation: String) async {
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
            "id": transactionId,  // OpenIAP compliance
            "productId": transaction.productID,
            "transactionId": transactionId,
            "transactionDate": transaction.purchaseDate.timeIntervalSince1970 * 1000,
            "transactionReceipt": transaction.jsonRepresentation.base64EncodedString(),
            "purchaseToken": jwsRepresentation,  // Unified field for iOS JWS and Android purchaseToken
            // TODO(v6.4.0): Remove deprecated jwsRepresentationIOS
            "jwsRepresentationIOS": jwsRepresentation,  // Deprecated - use purchaseToken - will be removed in v6.4.0
            "platform": "ios",
            "transactionState": getTransactionState(transaction),
            "quantityIOS": transaction.purchasedQuantity,
            "originalTransactionDateIOS": transaction.originalPurchaseDate.timeIntervalSince1970 * 1000,
            "originalTransactionIdentifierIOS": String(transaction.originalID),
            "appAccountTokenIOS": transaction.appAccountToken?.uuidString,
            "appBundleIdIOS": transaction.appBundleID,
            "productTypeIOS": transaction.productType.rawValue,
            "subscriptionGroupIdIOS": transaction.subscriptionGroupID,
            "isUpgradedIOS": transaction.isUpgraded,
            "ownershipTypeIOS": transaction.ownershipType.rawValue,
            "webOrderLineItemIdIOS": transaction.webOrderLineItemID
        ]
        
        // Add environment for iOS 16.0+
        if #available(iOS 16.0, *) {
            event["environmentIOS"] = transaction.environment.rawValue
        }
        
        // Add storefront info for iOS 17.0+
        if #available(iOS 17.0, *) {
            event["storefrontCountryCodeIOS"] = transaction.storefront.countryCode
            event["reasonIOS"] = transaction.reason.rawValue
        }
        
        // Add offer info for iOS 17.2+
        if #available(iOS 17.2, *) {
            if let offer = transaction.offer {
                event["offerIOS"] = [
                    "id": offer.id ?? "",
                    "type": offer.type.rawValue,
                    "paymentMode": offer.paymentMode?.rawValue ?? ""
                ]
            }
        }
        
        // Add price and currency if available from product
        if let product = products[transaction.productID] {
            event["priceIOS"] = product.price
            event["currencyIOS"] = product.priceFormatStyle.currencyCode ?? "USD"
        }
        
        if let expirationDate = transaction.expirationDate {
            event["expirationDate"] = expirationDate.timeIntervalSince1970 * 1000
            event["expirationDateIOS"] = expirationDate.timeIntervalSince1970 * 1000
        }
        
        if let revocationDate = transaction.revocationDate {
            event["revocationDate"] = revocationDate.timeIntervalSince1970 * 1000
            event["revocationDateIOS"] = revocationDate.timeIntervalSince1970 * 1000
            event["revocationReason"] = transaction.revocationReason?.rawValue
            event["revocationReasonIOS"] = transaction.revocationReason?.rawValue
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
                        "id": product.id,  // OpenIAP compliance
                        "price": "\(product.price)",
                        "currency": product.priceFormatStyle.currencyCode ?? "USD",
                        "localizedPrice": product.displayPrice,
                        "title": product.displayName,
                        "displayName": product.displayName,
                        "description": product.description,
                        "displayPrice": product.displayPrice,
                        "type": typeToString(product.type),
                        "originalPrice": "\(product.price)",
                        "platform": "ios",
                        "isFamilyShareable": product.isFamilyShareable,
                        "jsonRepresentation": String(data: product.jsonRepresentation, encoding: .utf8) ?? ""
                    ]
                    
                    // Add subscription info if available
                    if let subscription = product.subscription {
                        productInfo["subscriptionPeriodUnitIOS"] = unitToString(subscription.subscriptionPeriod.unit)
                        productInfo["subscriptionPeriodNumberIOS"] = "\(subscription.subscriptionPeriod.value)"
                        productInfo["subscriptionGroupIdIOS"] = subscription.subscriptionGroupID
                        
                        // Add complete subscription info
                        var subscriptionInfo: [String: Any] = [
                            "subscriptionGroupId": subscription.subscriptionGroupID,
                            "subscriptionPeriod": [
                                "unit": unitToString(subscription.subscriptionPeriod.unit),
                                "value": subscription.subscriptionPeriod.value
                            ]
                        ]
                        
                        // Add introductory offer if available
                        if let introOffer = subscription.introductoryOffer {
                            productInfo["introductoryPrice"] = introOffer.displayPrice
                            productInfo["introductoryPriceNumberOfPeriodsIOS"] = "\(introOffer.period.value)"
                            productInfo["introductoryPriceSubscriptionPeriodIOS"] = unitToString(introOffer.period.unit)
                            productInfo["introductoryPricePaymentModeIOS"] = "\(introOffer.paymentMode)"
                            
                            subscriptionInfo["introductoryOffer"] = [
                                "id": introOffer.id ?? "",
                                "period": [
                                    "unit": unitToString(introOffer.period.unit),
                                    "value": introOffer.period.value
                                ],
                                "periodCount": introOffer.periodCount,
                                "paymentMode": "\(introOffer.paymentMode)",
                                "type": "\(introOffer.type)",
                                "price": "\(introOffer.price)",
                                "displayPrice": introOffer.displayPrice
                            ]
                        }
                        
                        // Add promotional offers if available
                        if !subscription.promotionalOffers.isEmpty {
                            subscriptionInfo["promotionalOffers"] = subscription.promotionalOffers.map { offer in
                                return [
                                    "id": offer.id ?? "",
                                    "period": [
                                        "unit": unitToString(offer.period.unit),
                                        "value": offer.period.value
                                    ],
                                    "periodCount": offer.periodCount,
                                    "paymentMode": "\(offer.paymentMode)",
                                    "type": "\(offer.type)",
                                    "price": "\(offer.price)",
                                    "displayPrice": offer.displayPrice
                                ]
                            }
                            
                            // Also add promotional offer IDs for compatibility
                            productInfo["promotionalOfferIdsIOS"] = subscription.promotionalOffers.compactMap { $0.id }
                        }
                        
                        productInfo["subscription"] = subscriptionInfo
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
                    
                    var purchase: [String: Any] = [
                        "id": transactionId,
                        "productId": transaction.productID,
                        "transactionId": transactionId,
                        "transactionDate": transaction.purchaseDate.timeIntervalSince1970 * 1000,
                        "transactionReceipt": transaction.jsonRepresentation.base64EncodedString(),
                        "purchaseToken": verificationResult.jwsRepresentation,  // JWS for server validation (iOS 15+)
                        // TODO(v6.4.0): Remove deprecated jwsRepresentationIOS
                        "jwsRepresentationIOS": verificationResult.jwsRepresentation,  // Deprecated - use purchaseToken - will be removed in v6.4.0
                        "platform": "ios",
                        
                        // Add iOS-specific fields
                        "quantityIOS": transaction.purchasedQuantity,
                        "originalTransactionDateIOS": transaction.originalPurchaseDate.timeIntervalSince1970 * 1000,
                        "originalTransactionIdentifierIOS": String(transaction.originalID),
                        "appAccountTokenIOS": transaction.appAccountToken?.uuidString,
                        "appBundleIdIOS": transaction.appBundleID,
                        "productTypeIOS": transaction.productType.rawValue,
                        "subscriptionGroupIdIOS": transaction.subscriptionGroupID ?? "",
                        "isUpgradedIOS": transaction.isUpgraded,
                        "ownershipTypeIOS": transaction.ownershipType.rawValue,
                        "webOrderLineItemIdIOS": transaction.webOrderLineItemID
                    ]
                    
                    // Add environment for iOS 16.0+
                    if #available(iOS 16.0, *) {
                        purchase["environmentIOS"] = transaction.environment.rawValue
                    }
                    
                    // Add storefront info for iOS 17.0+
                    if #available(iOS 17.0, *) {
                        purchase["storefrontCountryCodeIOS"] = transaction.storefront.countryCode
                        purchase["reasonIOS"] = transaction.reason.rawValue
                    }
                    
                    // Add offer info for iOS 17.2+
                    if #available(iOS 17.2, *) {
                        if let offer = transaction.offer {
                            purchase["offerIOS"] = [
                                "id": offer.id ?? "",
                                "type": offer.type.rawValue,
                                "paymentMode": offer.paymentMode?.rawValue ?? ""
                            ]
                        }
                    }
                    
                    // Add expiration date if available
                    if let expirationDate = transaction.expirationDate {
                        purchase["expirationDateIOS"] = Int64(expirationDate.timeIntervalSince1970 * 1000)
                    }
                    
                    // Add revocation info if available
                    if let revocationDate = transaction.revocationDate {
                        purchase["revocationDateIOS"] = Int64(revocationDate.timeIntervalSince1970 * 1000)
                        purchase["revocationReasonIOS"] = transaction.revocationReason?.rawValue
                    }
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
                    await self.processTransaction(transaction, jwsRepresentation: verification.jwsRepresentation)
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
    
    // MARK: - Receipt Validation (StoreKit 2)
    
    // Helper function to process transaction and avoid code duplication
    private func processTransaction(_ verificationResult: VerificationResult<Transaction>) throws -> [String: Any] {
        let transaction = try self.checkVerified(verificationResult)
        
        var transactionData: [String: Any] = [
            "id": String(transaction.id),
            "productId": transaction.productID,
            // Convert to milliseconds for consistency
            "purchaseDate": Int64(transaction.purchaseDate.timeIntervalSince1970 * 1000),
            "originalPurchaseDate": Int64(transaction.originalPurchaseDate.timeIntervalSince1970 * 1000),
            "expirationDate": transaction.expirationDate != nil ? Int64(transaction.expirationDate!.timeIntervalSince1970 * 1000) : 0,
            "isRevoked": transaction.revocationDate != nil,
            "revocationDate": transaction.revocationDate != nil ? Int64(transaction.revocationDate!.timeIntervalSince1970 * 1000) : 0,
            "isUpgraded": transaction.isUpgraded,
            "subscriptionGroupID": transaction.subscriptionGroupID ?? "",
            "ownershipType": transaction.ownershipType.rawValue,
            "appAccountToken": transaction.appAccountToken?.uuidString ?? "",
            
            // Additional info for server validation
            "_comment": "Send 'purchaseToken' to your server for validation",
            "_serverValidationGuide": "https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/validating_receipts_with_the_app_store"
        ]
        
        // Add environment field only on iOS 16.0+
        if #available(iOS 16.0, *) {
            transactionData["environment"] = transaction.environment.rawValue
        } else {
            transactionData["environment"] = ""
        }
        
        return transactionData
    }
    
    private func validateReceiptIOS(productId: String, result: @escaping FlutterResult) {
        print("\(FlutterInappPurchasePlugin.TAG) validateReceiptIOS called for product: \(productId)")
        print("\(FlutterInappPurchasePlugin.TAG) ⚠️ This is for LOCAL TESTING only. For production, validate on your server using the JWS representation.")
        
        Task {
            // Get receipt data (legacy format - still useful for migration)
            var receiptData = ""
            if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
               let receiptDataRaw = try? Data(contentsOf: appStoreReceiptURL) {
                receiptData = receiptDataRaw.base64EncodedString()
            }
            
            var isValid = false
            var purchaseToken: String?  // Using purchaseToken for unified API (jwsRepresentation deprecated)
            var latestTransaction: [String: Any]?
            
            // Get the product and verify its latest transaction
            var product = self.products[productId]
            
            // If product not in cache, try to fetch it
            if product == nil {
                do {
                    let productList = try await Product.products(for: [productId])
                    if let fetchedProduct = productList.first {
                        self.products[productId] = fetchedProduct
                        product = fetchedProduct
                    }
                } catch {
                    print("\(FlutterInappPurchasePlugin.TAG) Failed to fetch product: \(error)")
                }
            }
            
            // Process the transaction if product exists
            if let product = product {
                if let verificationResult = await product.latestTransaction {
                    purchaseToken = verificationResult.jwsRepresentation  // JWS is the purchase token for iOS
                    
                    do {
                        latestTransaction = try processTransaction(verificationResult)
                        isValid = true
                        print("\(FlutterInappPurchasePlugin.TAG) ✅ Local validation successful")
                        print("\(FlutterInappPurchasePlugin.TAG) 📤 For production: Send the purchaseToken (JWS) to your server")
                    } catch {
                        isValid = false
                        print("\(FlutterInappPurchasePlugin.TAG) ❌ Local validation failed: \(error)")
                    }
                } else {
                    print("\(FlutterInappPurchasePlugin.TAG) No transaction found for product: \(productId)")
                }
            } else {
                print("\(FlutterInappPurchasePlugin.TAG) Product not found: \(productId)")
            }
            
            // Return the validation result
            let validationResult: [String: Any] = [
                "isValid": isValid,
                "receiptData": receiptData,
                "purchaseToken": purchaseToken ?? "",  // Unified field name (was jwsRepresentation)
                "jwsRepresentation": purchaseToken ?? "",  // Keep for backward compatibility (deprecated)
                "latestTransaction": latestTransaction as Any,
                "platform": "ios"  // Include platform for consistency
            ]
            
            await MainActor.run {
                result(validationResult)
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
        case .consumable: return "inapp"
        case .nonConsumable: return "inapp"
        case .nonRenewable: return "inapp"
        case .autoRenewable: return "subs"
        default: return "inapp"
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