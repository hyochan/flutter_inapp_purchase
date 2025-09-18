package dev.hyo.flutterinapppurchase

import android.app.Activity
import android.app.Application
import android.app.Application.ActivityLifecycleCallbacks
import android.content.Context
import android.os.Bundle
import android.util.Log
import dev.hyo.openiap.OpenIapError
import dev.hyo.openiap.OpenIapModule
import dev.hyo.openiap.listener.OpenIapPurchaseErrorListener
import dev.hyo.openiap.listener.OpenIapPurchaseUpdateListener
import dev.hyo.openiap.models.ProductRequest
import dev.hyo.openiap.models.RequestPurchaseParams
import dev.hyo.openiap.models.RequestSubscriptionAndroidProps
import dev.hyo.openiap.models.RequestSubscriptionAndroidProps.SubscriptionOffer
import dev.hyo.openiap.models.DeepLinkOptions
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import org.json.JSONObject

/**
 * AndroidInappPurchasePlugin (OpenIAP-backed)
 *
 * Implements the existing MethodChannel API using openiap-google (OpenIapModule),
 * and adds parity endpoints used by Expo modules for Android.
 */
class AndroidInappPurchasePlugin internal constructor() : MethodCallHandler, ActivityLifecycleCallbacks {
    private val job = Job()
    private val scope = CoroutineScope(Dispatchers.Main + job)

    private var context: Context? = null
    private var activity: Activity? = null
    private var channel: MethodChannel? = null

    private var connectionReady: Boolean = false
    private var listenersAttached = false
    private val connectionMutex = Mutex()

    // OpenIAP module instance
    private var openIap: OpenIapModule? = null

    private fun legacyErrorJson(
        code: String,
        defaultMessage: String,
        message: String? = null,
        productId: String? = null
    ): JSONObject {
        val payload = mutableMapOf<String, Any?>(
            "code" to code,
            "message" to (message ?: defaultMessage)
        )
        if (productId != null) {
            payload["productId"] = productId
        }
        return JSONObject(payload)
    }

    private fun MethodResultWrapper.error(
        code: String,
        defaultMessage: String,
        message: String? = null
    ) {
        val resolvedMessage = message ?: defaultMessage
        this.error(code, resolvedMessage, null)
    }

    fun setContext(context: Context?) {
        this.context = context
        if (context != null && openIap == null) {
            openIap = OpenIapModule(context)
        }
    }

    fun setActivity(activity: Activity?) {
        this.activity = activity
        openIap?.setActivity(activity)
    }

    fun setChannel(channel: MethodChannel?) {
        this.channel = channel
    }

    fun onDetachedFromActivity() {
        scope.launch {
            kotlin.runCatching { openIap?.endConnection() }
            connectionReady = false
        }
        // Cancel coroutine job to avoid leaks
        job.cancel()
    }

    // ActivityLifecycleCallbacks (no-ops except for cleanup)
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityResumed(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {
        if (this.activity === activity && context != null) {
            (context as Application).unregisterActivityLifecycleCallbacks(this)
            onDetachedFromActivity()
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ch = channel
        if (ch == null) {
            Log.e(TAG, "onMethodCall received for ${call.method} but channel is null. Cannot send result.")
            result.error(OpenIapError.DeveloperError.CODE, "MethodChannel is not attached", null)
            return
        }
        val safe = MethodResultWrapper(result, ch)

        // Quick methods that do not depend on billing readiness
        when (call.method) {
            "getStore" -> {
                safe.success(FlutterInappPurchasePlugin.getStore())
                return
            }
            "manageSubscription" -> {
                val sku = call.argument<String>("sku")
                val packageName = call.argument<String>("packageName")
                scope.launch {
                    try {
                        openIap?.deepLinkToSubscriptions(DeepLinkOptions(skuAndroid = sku, packageNameAndroid = packageName))
                        safe.success(true)
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
                return
            }
            "openPlayStoreSubscriptions" -> {
                scope.launch {
                    try {
                        openIap?.deepLinkToSubscriptions(DeepLinkOptions())
                        safe.success(true)
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
                return
            }
        }

        // Initialization / teardown
        when (call.method) {
            "initConnection" -> {
                if (connectionReady) {
                    safe.success("Already started. Call endConnection method if you want to start over.")
                    return
                }
                attachListenersIfNeeded()
                openIap?.setActivity(activity)
                scope.launch {
                    try {
                        val ok = openIap?.initConnection() ?: false
                        connectionReady = ok
                        // Emit connection-updated for compatibility
                        val item = JSONObject().apply { put("connected", ok) }
                        channel?.invokeMethod("connection-updated", item.toString())
                        if (ok) {
                            safe.success("Billing client ready")
                        } else {
                            safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "responseCode: -1")
                        }
                    } catch (e: Exception) {
                        safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, e.message)
                    }
                }
                return
            }
            "endConnection" -> {
                scope.launch {
                    try {
                        openIap?.endConnection()
                        connectionReady = false
                        safe.success("Billing client has ended.")
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
                return
            }
            "isReady" -> {
                safe.success(connectionReady)
                return
            }
        }

        // Lazily init connection on demand
        if (!connectionReady && call.method in setOf("fetchProducts", "getAvailableItems", "getStorefrontAndroid", "requestPurchase", "getProducts", "getSubscriptions", "getAvailableItemsByType", "getPurchaseHistoryByType", "buyItemByType", "acknowledgePurchase", "consumeProduct", "consumePurchase", "acknowledgePurchaseAndroid", "consumePurchaseAndroid")) {
            // Best-effort prepare connection
            scope.launch {
                connectionMutex.withLock {
                    try {
                        attachListenersIfNeeded()
                        openIap?.setActivity(activity)
                        val ok = openIap?.initConnection() ?: false
                        connectionReady = ok
                        val item = JSONObject().apply { put("connected", ok) }
                        channel?.invokeMethod("connection-updated", item.toString())
                    } catch (e: Exception) {
                        Log.e(TAG, "Lazy connection initialization failed", e)
                        connectionReady = false
                    }
                }
            }
        }

        when (call.method) {
            // Expo parity: fetchProducts(type, skuArr[])
            "fetchProducts" -> {
                val typeStr = call.argument<String>("type") ?: "inapp"
                val skuArr = call.argument<List<String>>("skuArr")
                    ?: call.argument<List<String>>("skus")
                    ?: call.argument<List<String>>("productIds")
                    ?: emptyList()
                val reqType = ProductRequest.ProductRequestType.fromString(typeStr)
                scope.launch {
                    // Ensure connection
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection() ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@launch
                                }
                            }
                        } catch (e: Exception) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            return@launch
                        }
                    }
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val products = iap.fetchProducts(ProductRequest(skuArr, reqType))
                        val arr = JSONArray()
                        products.forEach { p ->
                            val map = p.toJSON()
                            val obj = JSONObject(map)
                            arr.put(obj)
                        }
                        safe.success(arr.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.QueryProduct.CODE, OpenIapError.QueryProduct.MESSAGE, e.message)
                    }
                }
            }

            // Expo parity: getAvailableItems()
            "getAvailableItems" -> {
                scope.launch {
                    // Ensure connection
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection() ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@launch
                                }
                            }
                        } catch (e: Exception) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            return@launch
                        }
                    }
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val purchases = iap.getAvailablePurchases(null)
                        val arr = JSONArray(purchases.map { it.toJSON() })
                        safe.success(arr.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }

            

            // Expo parity: requestPurchase(params)
            "requestPurchase" -> {
                val params = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                val typeStr = params["type"] as? String ?: "inapp"
                val skus: List<String> =
                    (params["skus"] as? List<*>)?.filterIsInstance<String>()
                        ?: (params["skuArr"] as? List<*>)?.filterIsInstance<String>()
                        ?: emptyList()
                val skusNormalized = skus.filter { it.isNotBlank() }
                val obfuscatedAccountId =
                    (params["obfuscatedAccountIdAndroid"] ?: params["obfuscatedAccountId"]) as? String
                val obfuscatedProfileId =
                    (params["obfuscatedProfileIdAndroid"] ?: params["obfuscatedProfileId"]) as? String
                val isOfferPersonalized = params["isOfferPersonalized"] as? Boolean ?: false

                // Validate SKUs
                if (skusNormalized.isEmpty()) {
                    channel?.invokeMethod(
                        "purchase-error",
                        legacyErrorJson(OpenIapError.EmptySkuList.CODE, OpenIapError.EmptySkuList.MESSAGE, "Empty SKUs provided").toString()
                    )
                    safe.error(OpenIapError.EmptySkuList.CODE, OpenIapError.EmptySkuList.MESSAGE, "Empty SKUs provided")
                    return
                }

                scope.launch {
                    // Ensure connection and listeners under mutex
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection() ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                    val err = legacyErrorJson(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    channel?.invokeMethod("purchase-error", err.toString())
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@withLock
                                }
                            }
                        } catch (e: Exception) {
                            val err = legacyErrorJson(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            channel?.invokeMethod("purchase-error", err.toString())
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            return@withLock
                        }
                    }

                try {
                    val iap = openIap
                    if (iap == null) {
                        safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                        return@launch
                    }
                    val offers = (params["subscriptionOffers"] as? List<*>)?.mapNotNull { entry ->
                        val map = entry as? Map<*, *> ?: return@mapNotNull null
                        val sku = map["sku"] as? String ?: return@mapNotNull null
                        val offerToken = map["offerToken"] as? String ?: return@mapNotNull null
                        SubscriptionOffer(sku = sku, offerToken = offerToken)
                    }

                    val offerList = offers ?: emptyList()

                    val requestParams = RequestPurchaseParams(
                        skus = skusNormalized,
                        obfuscatedAccountIdAndroid = obfuscatedAccountId,
                        obfuscatedProfileIdAndroid = obfuscatedProfileId,
                        isOfferPersonalized = isOfferPersonalized,
                        subscriptionOffers = offerList
                    )

                    iap.requestPurchase(
                        requestParams,
                        ProductRequest.ProductRequestType.fromString(typeStr)
                    )
                    // Success signaled by purchase-updated event
                    safe.success(null)
                } catch (e: Exception) {
                    channel?.invokeMethod(
                        "purchase-error",
                        legacyErrorJson(OpenIapError.PurchaseFailed.CODE, OpenIapError.PurchaseFailed.MESSAGE, e.message).toString()
                    )
                    safe.error(OpenIapError.PurchaseFailed.CODE, OpenIapError.PurchaseFailed.MESSAGE, e.message)
                }
            }
            }

            // -----------------------------------------------------------------
            // Android-suffix stable APIs (kept)
            // -----------------------------------------------------------------
            "getStorefrontAndroid" -> {
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val code = iap.getStorefront()
                        safe.success(code)
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "deepLinkToSubscriptionsAndroid" -> {
                val params = call.arguments as? Map<*, *>
                val sku = params?.get("sku") as? String ?: params?.get("skuAndroid") as? String
                val pkg = params?.get("packageName") as? String
                    ?: params?.get("packageNameAndroid") as? String
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        iap.deepLinkToSubscriptions(DeepLinkOptions(skuAndroid = sku, packageNameAndroid = pkg))
                        safe.success(null)
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "acknowledgePurchaseAndroid" -> {
                val token = call.argument<String>("token") ?: call.argument<String>("purchaseToken")
                if (token.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, OpenIapError.DeveloperError.MESSAGE, "Missing purchaseToken")
                    return
                }
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        iap.acknowledgePurchaseAndroid(token)
                        val resp = JSONObject().apply { put("responseCode", 0) }
                        safe.success(resp.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            
            "consumePurchaseAndroid" -> {
                val token = call.argument<String>("token") ?: call.argument<String>("purchaseToken")
                if (token.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, OpenIapError.DeveloperError.MESSAGE, "Missing purchaseToken")
                    return
                }
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        iap.consumePurchaseAndroid(token)
                        val resp = JSONObject().apply {
                            put("responseCode", 0)
                            put("purchaseToken", token)
                        }
                        safe.success(resp.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }

            // -----------------------------------------------------------------
            // Legacy/compat API (Deprecated)
            // NOTE: These endpoints are kept for backwards compatibility only
            // and will be removed in 7.0.0. Please migrate to:
            //  - fetchProducts(type, skuArr)
            //  - getAvailableItems()
            //  - requestPurchase(params)
            // -----------------------------------------------------------------
            // Legacy/compat product queries
            "getProducts" -> {
                logDeprecated("getProducts", "Use fetchProducts(type, skuArr) instead")
                val productIds = call.argument<ArrayList<String>>("productIds") ?: arrayListOf()
                scope.launch {
                    // Ensure connection for legacy path
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection() ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@launch
                                }
                            }
                        } catch (e: Exception) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            return@launch
                        }
                    }
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val products = iap.fetchProducts(
                            ProductRequest(productIds, ProductRequest.ProductRequestType.InApp)
                        )
                        val arr = JSONArray()
                        products.forEach { p ->
                            val map = p.toJSON()
                            val obj = JSONObject(map)
                            if (!obj.has("productId")) obj.put("productId", map["id"])
                            arr.put(obj)
                        }
                        safe.success(arr.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.QueryProduct.CODE, OpenIapError.QueryProduct.MESSAGE, e.message)
                    }
                }
            }
            "getSubscriptions" -> {
                logDeprecated("getSubscriptions", "Use fetchProducts(type, skuArr) with type=subs")
                val productIds = call.argument<ArrayList<String>>("productIds") ?: arrayListOf()
                scope.launch {
                    // Ensure connection for legacy path
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection() ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@launch
                                }
                            }
                        } catch (e: Exception) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            return@launch
                        }
                    }
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val products = iap.fetchProducts(
                            ProductRequest(productIds, ProductRequest.ProductRequestType.Subs)
                        )
                        val arr = JSONArray()
                        products.forEach { p ->
                            val map = p.toJSON()
                            val obj = JSONObject(map)
                            if (!obj.has("productId")) obj.put("productId", map["id"])
                            arr.put(obj)
                        }
                        safe.success(arr.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.QueryProduct.CODE, OpenIapError.QueryProduct.MESSAGE, e.message)
                    }
                }
            }

            // Legacy/compat purchases queries
            "getAvailableItemsByType" -> {
                logDeprecated("getAvailableItemsByType", "Use getAvailableItems() instead")
                val typeStr = call.argument<String>("type") ?: "inapp"
                val reqType = ProductRequest.ProductRequestType.fromString(typeStr)
                scope.launch {
                    // Ensure connection for legacy path
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection() ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@launch
                                }
                            }
                        } catch (e: Exception) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            return@launch
                        }
                    }
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val purchases = iap.getAvailableItems(reqType)
                        val arr = JSONArray(purchases.map { it.toJSON() })
                        safe.success(arr.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "getPurchaseHistoryByType" -> {
                logDeprecated("getPurchaseHistoryByType", "Use getAvailableItems() instead")
                val typeStr = call.argument<String>("type") ?: "inapp"
                val reqType = ProductRequest.ProductRequestType.fromString(typeStr)
                scope.launch {
                    // Ensure connection for legacy path
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection() ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@launch
                                }
                            }
                        } catch (e: Exception) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            return@launch
                        }
                    }
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val purchases = iap.getAvailableItems(reqType)
                        val arr = JSONArray(purchases.map { it.toJSON() })
                        safe.success(arr.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }

            // Legacy/compat purchase flow
            "buyItemByType" -> {
                logDeprecated("buyItemByType", "Use requestPurchase(params) instead")
                val typeStr = call.argument<String>("type") ?: "inapp"
                val productId = call.argument<String>("productId")
                    ?: call.argument<String>("sku")
                    ?: call.argument<ArrayList<String>>("skus")?.firstOrNull()
                val obfuscatedAccountId = call.argument<String>("obfuscatedAccountId")
                val obfuscatedProfileId = call.argument<String>("obfuscatedProfileId")
                val isOfferPersonalized = call.argument<Boolean>("isOfferPersonalized") ?: false

                if (productId.isNullOrBlank()) {
                    channel?.invokeMethod(
                        "purchase-error",
                        legacyErrorJson(OpenIapError.DeveloperError.CODE, OpenIapError.DeveloperError.MESSAGE, "Missing productId").toString()
                    )
                    safe.error(OpenIapError.DeveloperError.CODE, OpenIapError.DeveloperError.MESSAGE, "Missing productId")
                    return
                }

                scope.launch {
                    // Ensure connection and listeners under mutex
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection() ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                val err = legacyErrorJson(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                channel?.invokeMethod("purchase-error", err.toString())
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@withLock
                                }
                            }
                        } catch (e: Exception) {
                            val err = legacyErrorJson(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            channel?.invokeMethod("purchase-error", err.toString())
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                            return@withLock
                        }
                    }
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val requestParams = RequestPurchaseParams(
                            skus = listOf(productId),
                            obfuscatedAccountIdAndroid = obfuscatedAccountId,
                            obfuscatedProfileIdAndroid = obfuscatedProfileId,
                            isOfferPersonalized = isOfferPersonalized,
                            subscriptionOffers = emptyList()
                        )

                        iap.requestPurchase(
                            requestParams,
                            ProductRequest.ProductRequestType.fromString(typeStr)
                        )
                        safe.success(null)
                    } catch (e: Exception) {
                        channel?.invokeMethod(
                            "purchase-error",
                            legacyErrorJson(OpenIapError.PurchaseFailed.CODE, OpenIapError.PurchaseFailed.MESSAGE, e.message).toString()
                        )
                        safe.error(OpenIapError.PurchaseFailed.CODE, OpenIapError.PurchaseFailed.MESSAGE, e.message)
                    }
                }
            }

            // Finish/acknowledge/consume (compat)
            "acknowledgePurchase" -> {
                logDeprecated("acknowledgePurchase", "Use acknowledgePurchaseAndroid(token) instead")
                val token = call.argument<String>("purchaseToken")
                if (token.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, OpenIapError.DeveloperError.MESSAGE, "Missing purchaseToken")
                    return
                }
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        iap.acknowledgePurchaseAndroid(token)
                        val resp = JSONObject().apply { put("responseCode", 0) }
                        safe.success(resp.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            

            "consumeProduct" -> {
                logDeprecated("consumeProduct", "Use finishTransaction(purchase, isConsumable=true) at higher-level API")
                val token = call.argument<String>("purchaseToken")
                if (token.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, OpenIapError.DeveloperError.MESSAGE, "Missing purchaseToken")
                    return
                }
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        iap.consumePurchaseAndroid(token)
                        val resp = JSONObject().apply {
                            put("responseCode", 0)
                            put("purchaseToken", token)
                        }
                        safe.success(resp.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "consumePurchase" -> {
                logDeprecated("consumePurchase", "Use finishTransaction(purchase, isConsumable=true) at higher-level API")
                val token = call.argument<String>("purchaseToken")
                if (token.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, OpenIapError.DeveloperError.MESSAGE, "Missing purchaseToken")
                    return
                }
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.success(false)
                            return@launch
                        }
                        iap.consumePurchaseAndroid(token)
                        safe.success(true)
                    } catch (e: Exception) {
                        safe.success(false)
                    }
                }
            }
            

            // No-op legacy (Deprecated — will be removed in 7.0.0)
            "showInAppMessages" -> {
                logDeprecated("showInAppMessages", "No-op; removed in 7.0.0")
                safe.success(true)
            }

            else -> safe.notImplemented()
        }
    }

    @Deprecated("Deprecated channel endpoint; will be removed in 7.0.0")
    private fun logDeprecated(name: String, message: String) {
        Log.w(TAG, "[$name] is deprecated and will be removed in 7.0.0. $message")
    }

    private fun attachListenersIfNeeded() {
        if (listenersAttached) return
        listenersAttached = true
        openIap?.addPurchaseUpdateListener(OpenIapPurchaseUpdateListener { p ->
            scope.launch {
                try {
                    val payload = JSONObject(p.toJSON())
                    channel?.invokeMethod("purchase-updated", payload.toString())
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to send purchase-updated", e)
                }
            }
        })
        openIap?.addPurchaseErrorListener(OpenIapPurchaseErrorListener { e ->
            scope.launch {
                try {
                    val payload = when (e) {
                        is OpenIapError -> JSONObject(e.toJSON())
                        else -> JSONObject(
                            mapOf(
                                "code" to OpenIapError.PurchaseFailed.CODE,
                                "message" to (e.message ?: "Purchase error"),
                                "platform" to "android"
                            )
                        )
                    }
                    channel?.invokeMethod("purchase-error", payload.toString())
                } catch (ex: Exception) {
                    Log.e(TAG, "Failed to send purchase-error", ex)
                }
            }
        })
    }

    companion object {
        private const val TAG = "InappPurchasePlugin"
        private const val PLAY_STORE_URL = "https://play.google.com/store/account/subscriptions"
    }
}
