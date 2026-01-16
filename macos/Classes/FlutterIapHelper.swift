import Foundation
import OpenIAP

enum FlutterIapHelper {
    // MARK: - Sanitization

    private static let identifierKeys: Set<String> = [
        "id",
        "transactionId",
        "productId",
        "offerId",
        "originalTransactionIdentifierIOS",
        "subscriptionGroupIdIOS",
        "webOrderLineItemIdIOS",
        "orderIdAndroid",
        "obfuscatedAccountIdAndroid",
        "obfuscatedProfileIdAndroid"
    ]

    static func sanitizeDictionary(_ dictionary: [String: Any?]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dictionary {
            guard let sanitizedValue = sanitizeValue(value) else { continue }

            if let number = sanitizedValue as? NSNumber, identifierKeys.contains(key) {
                result[key] = number.stringValue
            } else {
                result[key] = sanitizedValue
            }
        }
        return result
    }

    static func sanitizeArray(_ array: [[String: Any?]]) -> [[String: Any]] {
        array.map { sanitizeDictionary($0) }
    }

    static func sanitizeValue(_ value: Any?) -> Any? {
        guard let value else { return nil }

        if let dictionary = value as? [String: Any?] {
            return sanitizeDictionary(dictionary)
        }

        if let dictionary = value as? [String: Any] {
            let optionalDictionary = dictionary.reduce(into: [String: Any?]()) { result, element in
                result[element.key] = element.value
            }
            return sanitizeDictionary(optionalDictionary)
        }

        if let array = value as? [Any?] {
            return array.compactMap { sanitizeValue($0) }
        }

        if let array = value as? [Any] {
            return array.compactMap { sanitizeValue($0) }
        }

        return value
    }

    static func jsonString(from value: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(value) else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: []) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Parsing helpers

    static func parseProductQueryType(_ rawValue: String?) -> ProductQueryType {
        guard let raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return .all
        }
        switch raw.lowercased() {
        case "inapp", ProductQueryType.inApp.rawValue:
            return .inApp
        case ProductQueryType.subs.rawValue:
            return .subs
        case ProductQueryType.all.rawValue:
            return .all
        default:
            return .all
        }
    }

    static func decodeProductRequest(from payload: [String: Any]) throws -> ProductRequest {
        if let skus = payload["skus"] as? [String], !skus.isEmpty {
            let type = parseProductQueryType(payload["type"] as? String)
            return try OpenIapSerialization.productRequest(skus: skus, type: type)
        }

        let indexedSkus = payload.keys
            .compactMap { Int($0) }
            .sorted()
            .compactMap { payload[String($0)] as? String }

        if !indexedSkus.isEmpty {
            return try OpenIapSerialization.productRequest(skus: indexedSkus, type: .all)
        }

        return try OpenIapSerialization.decode(object: payload, as: ProductRequest.self)
    }

    static func decodePurchaseOptions(from dictionary: [String: Any]) throws -> PurchaseOptions {
        try OpenIapSerialization.purchaseOptions(from: dictionary)
    }

    static func decodePurchaseOptions(alsoPublish: Bool, onlyIncludeActive: Bool) throws -> PurchaseOptions {
        try decodePurchaseOptions(from: [
            "alsoPublishToEventListenerIOS": alsoPublish,
            "onlyIncludeActiveItemsIOS": onlyIncludeActive
        ])
    }

    static func decodeRequestPurchaseProps(from payload: [String: Any]) throws -> RequestPurchaseProps {
        if payload["requestPurchase"] != nil || payload["requestSubscription"] != nil {
            FlutterIapLog.payload("decodeRequestPurchaseProps.normalized", payload: sanitizeValue(payload))
            return try OpenIapSerialization.decode(object: payload, as: RequestPurchaseProps.self)
        }

        if let request = payload["request"] {
            let parsedType = parseProductQueryType(payload["type"] as? String)
            let purchaseType: ProductQueryType = parsedType == .all ? .inApp : parsedType
            var normalized: [String: Any] = ["type": purchaseType.rawValue]
            switch purchaseType {
            case .subs:
                normalized["requestSubscription"] = request
            case .inApp:
                normalized["requestPurchase"] = request
            case .all:
                break
            }
            FlutterIapLog.payload("decodeRequestPurchaseProps.normalized", payload: sanitizeValue(normalized))
            return try OpenIapSerialization.decode(object: normalized, as: RequestPurchaseProps.self)
        }

        if let sku = payload["sku"] as? String, !sku.isEmpty {
            let parsedType = parseProductQueryType(payload["type"] as? String)
            let purchaseType: ProductQueryType = parsedType == .subs ? .subs : .inApp
            var iosPayload: [String: Any?] = payload
            iosPayload["sku"] = sku
            let normalized: [String: Any] = [
                "type": purchaseType.rawValue,
                purchaseType == .subs ? "requestSubscription" : "requestPurchase": [
                    "ios": sanitizeDictionary(iosPayload)
                ]
            ]
            FlutterIapLog.payload("decodeRequestPurchaseProps.normalized", payload: sanitizeValue(normalized))
            return try OpenIapSerialization.decode(object: normalized, as: RequestPurchaseProps.self)
        }

        throw PurchaseError.make(code: .developerError, message: "Invalid purchase request payload")
    }

    static func decodePurchaseInput(from payload: Any) throws -> PurchaseInput {
        try OpenIapSerialization.purchaseInput(from: payload)
    }

    static func fallbackPurchaseInput(for transactionId: String) throws -> PurchaseInput {
        let payload: [String: Any] = [
            "id": transactionId,
            "ids": [],
            "isAutoRenewing": false,
            "platform": IapPlatform.ios.rawValue,
            "productId": "",
            "purchaseState": PurchaseState.purchased.rawValue,
            "purchaseToken": transactionId,
            "quantity": 1,
            "transactionDate": 0
        ]
        return try decodePurchaseInput(from: payload)
    }

    static func decodeVerifyPurchaseProps(for sku: String) throws -> VerifyPurchaseProps {
        try OpenIapSerialization.verifyPurchaseProps(from: ["sku": sku])
    }
}
