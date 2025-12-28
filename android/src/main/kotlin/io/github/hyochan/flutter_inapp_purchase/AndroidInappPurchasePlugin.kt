package io.github.hyochan.flutter_inapp_purchase

import android.app.Activity
import android.app.Application
import android.app.Application.ActivityLifecycleCallbacks
import android.content.Context
import android.os.Bundle
import dev.hyo.openiap.AndroidSubscriptionOfferInput
import dev.hyo.openiap.BillingProgramAndroid
import dev.hyo.openiap.DeepLinkOptions
import dev.hyo.openiap.DeveloperBillingLaunchModeAndroid
import dev.hyo.openiap.DeveloperBillingOptionParamsAndroid
import dev.hyo.openiap.ExternalLinkLaunchModeAndroid
import dev.hyo.openiap.ExternalLinkTypeAndroid
import dev.hyo.openiap.FetchProductsResult
import dev.hyo.openiap.FetchProductsResultProducts
import dev.hyo.openiap.FetchProductsResultSubscriptions
import dev.hyo.openiap.InitConnectionConfig
import dev.hyo.openiap.LaunchExternalLinkParamsAndroid
import dev.hyo.openiap.OpenIapError
import dev.hyo.openiap.OpenIapLog
import dev.hyo.openiap.OpenIapModule
import dev.hyo.openiap.ProductQueryType
import dev.hyo.openiap.ProductRequest
import dev.hyo.openiap.Purchase
import dev.hyo.openiap.RequestPurchaseProps
import dev.hyo.openiap.listener.OpenIapDeveloperProvidedBillingListener
import dev.hyo.openiap.listener.OpenIapPurchaseErrorListener
import dev.hyo.openiap.listener.OpenIapPurchaseUpdateListener
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
import java.util.Locale

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

    private fun parseQueryType(raw: String?): ProductQueryType {
        val normalized = raw?.lowercase(Locale.ROOT) ?: "inapp"
        return when {
            normalized == "all" -> ProductQueryType.All
            normalized.contains("sub") -> ProductQueryType.Subs
            normalized.contains("consumable") -> ProductQueryType.InApp
            normalized == "in-app" || normalized == "inapp" || normalized == "in_app" -> ProductQueryType.InApp
            else -> ProductQueryType.InApp
        }
    }

    private fun parsePurchaseType(raw: String?): ProductQueryType {
        val type = parseQueryType(raw)
        return if (type == ProductQueryType.Subs) ProductQueryType.Subs else ProductQueryType.InApp
    }

    private fun fetchResultToJsonArray(
        result: FetchProductsResult,
        deduplicate: Boolean = false
    ): JSONArray {
        val entries: List<Map<String, Any?>> = when (result) {
            is FetchProductsResultProducts -> result.value?.map { it.toJson() }
                ?: emptyList()
            is FetchProductsResultSubscriptions -> result.value?.map { it.toJson() }
                ?: emptyList()
            else -> emptyList<Map<String, Any?>>()
        }
        val array = JSONArray()
        val seenIds = mutableSetOf<String>()

        entries.forEach { entry ->
            val id = entry["id"] as? String

            // Handle deduplication for ProductQueryType.All bug in OpenIAP
            if (deduplicate && id != null) {
                if (!seenIds.add(id)) {
                    OpenIapLog.w(TAG, "OpenIAP returned duplicate product with id: $id (filtering out duplicate)")
                    return@forEach
                }
            }

            val obj = JSONObject(entry)
            // Always add productId for compatibility, handling null/blank values
            val productIdValue = obj.opt("productId")
            val hasUsableProductId = when (productIdValue) {
                null, JSONObject.NULL -> false
                is String -> productIdValue.isNotBlank()
                else -> true
            }
            if (!hasUsableProductId && !id.isNullOrBlank()) {
                obj.put("productId", id)
            }
            array.put(obj)
        }
        return array
    }

    private fun purchasesToJsonArray(purchases: List<Purchase>): JSONArray {
        val array = JSONArray()
        purchases.forEach { purchase ->
            array.put(JSONObject(purchase.toJson()))
        }
        return array
    }

    private fun buildRequestPurchaseProps(
        type: ProductQueryType,
        skus: List<String>,
        obfuscatedAccountId: String?,
        obfuscatedProfileId: String?,
        isOfferPersonalized: Boolean,
        subscriptionOffers: List<AndroidSubscriptionOfferInput>,
        purchaseTokenAndroid: String?,
        replacementModeAndroid: Int?,
        developerBillingOption: DeveloperBillingOptionParamsAndroid? = null
    ): RequestPurchaseProps {
        val androidPayload = mutableMapOf<String, Any?>().apply {
            put(KEY_SKUS, skus)
            put(KEY_IS_OFFER_PERSONALIZED, isOfferPersonalized)
            obfuscatedAccountId?.let { put(KEY_OBFUSCATED_ACCOUNT, it) }
            obfuscatedProfileId?.let { put(KEY_OBFUSCATED_PROFILE, it) }
            developerBillingOption?.let { put(KEY_DEVELOPER_BILLING_OPTION, it.toJson()) }
        }

        val root = mutableMapOf<String, Any?>(
            KEY_TYPE to type.toJson()
        )

        return when (type) {
            ProductQueryType.Subs -> {
                purchaseTokenAndroid?.let { androidPayload[KEY_PURCHASE_TOKEN] = it }
                replacementModeAndroid?.let { androidPayload[KEY_REPLACEMENT_MODE] = it }
                if (subscriptionOffers.isNotEmpty()) {
                    androidPayload[KEY_SUBSCRIPTION_OFFERS] = subscriptionOffers.map { it.toJson() }
                }
                root[KEY_REQUEST_SUBSCRIPTION] = mapOf(KEY_ANDROID to androidPayload)
                RequestPurchaseProps.fromJson(root)
            }
            ProductQueryType.InApp -> {
                root[KEY_REQUEST_PURCHASE] = mapOf(KEY_ANDROID to androidPayload)
                RequestPurchaseProps.fromJson(root)
            }
            ProductQueryType.All -> throw IllegalArgumentException(
                "type must be InApp or Subs when requesting a purchase"
            )
        }
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
            OpenIapLog.e("onMethodCall received for ${call.method} but channel is null. Cannot send result.")
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
                // Parse alternativeBillingModeAndroid and enableBillingProgramAndroid from arguments
                val params = call.arguments as? Map<*, *>
                val configMap = mutableMapOf<String, Any?>()
                params?.get("alternativeBillingModeAndroid")?.let {
                    configMap["alternativeBillingModeAndroid"] = it
                }
                params?.get("enableBillingProgramAndroid")?.let {
                    configMap["enableBillingProgramAndroid"] = it
                }
                val newConfig = if (configMap.isEmpty()) {
                    InitConnectionConfig()
                } else {
                    InitConnectionConfig.fromJson(configMap)
                }

                OpenIapLog.d(TAG, "initConnection called with config: $configMap")

                attachListenersIfNeeded()
                openIap?.setActivity(activity)
                scope.launch {
                    try {
                        // ALWAYS end connection first to reset configuration
                        // This ensures we start fresh regardless of current state
                        try {
                            OpenIapLog.d(TAG, "Ending connection before reinitializing (current ready state: $connectionReady)")
                            openIap?.endConnection()
                            connectionReady = false

                            // WORKAROUND: OpenIAP's endConnection() is synchronous but may trigger
                            // async cleanup in the background (e.g., disconnecting from Play Store).
                            // A small delay reduces the risk of race conditions where initConnection()
                            // is called before cleanup completes. This is not ideal but necessary
                            // until OpenIAP provides an async endConnection() or callback mechanism.
                            // Increase this delay if experiencing connection issues.
                            kotlinx.coroutines.delay(300)
                        } catch (e: Exception) {
                            OpenIapLog.w(TAG, "Error ending connection: ${e.message}")
                        }

                        OpenIapLog.d(TAG, "Initializing connection with Alternative Billing mode: ${configMap.get("alternativeBillingModeAndroid") ?: "none"}")
                        val ok = openIap?.initConnection(newConfig) ?: false
                        connectionReady = ok
                        OpenIapLog.d(TAG, "Connection initialized: $ok")

                        // Emit connection-updated for compatibility
                        val item = JSONObject().apply { put("connected", ok) }
                        channel?.invokeMethod("connection-updated", item.toString())
                        if (ok) {
                            safe.success("Billing client ready")
                        } else {
                            safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "responseCode: -1")
                        }
                    } catch (e: Exception) {
                        OpenIapLog.e("Error during initConnection: ${e.message}", e)
                        safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, e.message)
                    }
                }
                return
            }
            "endConnection" -> {
                scope.launch {
                    try {
                        OpenIapLog.d(TAG, "endConnection called")
                        openIap?.endConnection()
                        connectionReady = false
                        OpenIapLog.d(TAG, "Connection ended successfully")
                        safe.success("Billing client has ended.")
                    } catch (e: Exception) {
                        OpenIapLog.e("Error ending connection: ${e.message}", e)
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


        when (call.method) {
            // Expo parity: fetchProducts(type, skuArr[])
            "fetchProducts" -> {
                val typeStr = call.argument<String>("type")
                val skuArr = call.argument<List<String>>("skuArr")
                    ?: call.argument<List<String>>("skus")
                    ?: call.argument<List<String>>("productIds")
                    ?: emptyList()
                val queryType = parseQueryType(typeStr)
                scope.launch {
                    withBillingReady(safe, autoInit = true) {
                        try {
                            val iap = openIap
                            if (iap == null) {
                                safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                                return@withBillingReady
                            }
                            val result = iap.fetchProducts(ProductRequest(skuArr, queryType))
                            val arr = fetchResultToJsonArray(result, queryType == ProductQueryType.All)
                            safe.success(arr.toString())
                        } catch (e: Exception) {
                            safe.error(OpenIapError.QueryProduct.CODE, OpenIapError.QueryProduct.MESSAGE, e.message)
                        }
                    }
                }
            }

            // Expo parity: getAvailableItems()
            "getAvailableItems" -> {
                scope.launch {
                    withBillingReady(safe, autoInit = true) {
                        try {
                            val iap = openIap
                            if (iap == null) {
                                safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                                return@withBillingReady
                            }
                            val purchases = iap.getAvailablePurchases(null)
                            val arr = purchasesToJsonArray(purchases)
                            safe.success(arr.toString())
                        } catch (e: Exception) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                        }
                    }
                }
            }

            "getActiveSubscriptions" -> {
                @Suppress("UNCHECKED_CAST")
                val subscriptionIds = call.arguments as? List<String>

                OpenIapLog.d(TAG, "getActiveSubscriptions called with subscriptionIds: $subscriptionIds")

                scope.launch {
                    withBillingReady(safe) {
                        try {
                            val iap = openIap
                            if (iap == null) {
                                safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                                return@withBillingReady
                            }
                            val subscriptions = iap.getActiveSubscriptions(subscriptionIds)
                            val arr = JSONArray()
                            subscriptions.forEach { subscription ->
                                arr.put(JSONObject(subscription.toJson()))
                            }
                            safe.success(arr.toString())
                        } catch (e: Exception) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                        }
                    }
                }
            }

            "requestPurchase" -> {
                val params = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                val typeStr = params["type"] as? String
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
                val purchaseTokenAndroid = params["purchaseTokenAndroid"] as? String
                val replacementModeAndroid = (params["replacementModeAndroid"] as? Number)?.toInt()
                val useAlternativeBilling = params["useAlternativeBilling"] as? Boolean

                // Parse developerBillingOption for External Payments (8.3.0+)
                val developerBillingOptionMap = params[KEY_DEVELOPER_BILLING_OPTION] as? Map<*, *>
                val developerBillingOption = developerBillingOptionMap?.let { optionMap ->
                    try {
                        val billingProgram = BillingProgramAndroid.fromJson(
                            optionMap["billingProgram"] as? String ?: "unspecified"
                        )
                        val launchMode = DeveloperBillingLaunchModeAndroid.fromJson(
                            optionMap["launchMode"] as? String ?: "unspecified"
                        )
                        val linkUri = optionMap["linkUri"] as? String
                        if (!linkUri.isNullOrBlank()) {
                            DeveloperBillingOptionParamsAndroid(
                                billingProgram = billingProgram,
                                launchMode = launchMode,
                                linkUri = linkUri
                            )
                        } else {
                            null
                        }
                    } catch (e: Exception) {
                        OpenIapLog.w(TAG, "Failed to parse developerBillingOption: ${e.message}")
                        null
                    }
                }

                // Validate SKUs
                if (skusNormalized.isEmpty()) {
                    safe.error(OpenIapError.EmptySkuList.CODE, OpenIapError.EmptySkuList.MESSAGE, "Empty SKUs provided")
                    return
                }

                OpenIapLog.d(TAG, "requestPurchase called")
                OpenIapLog.d(TAG, "  - useAlternativeBilling = $useAlternativeBilling")
                OpenIapLog.d(TAG, "  - connectionReady = $connectionReady")
                OpenIapLog.d(TAG, "  - params keys = ${params.keys.joinToString()}")

                scope.launch {
                    // Ensure connection and listeners under mutex
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)

                            // Check if connection is ready
                            if (!connectionReady) {
                                safe.error(
                                    OpenIapError.NotPrepared.CODE,
                                    OpenIapError.NotPrepared.MESSAGE,
                                    "Connection not ready. Call initConnection() first with the desired billing mode."
                                )
                                return@launch
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
                    val offers = (params["subscriptionOffers"] as? List<*>)?.mapNotNull { entry ->
                        val map = entry as? Map<*, *> ?: return@mapNotNull null
                        val sku = map["sku"] as? String ?: return@mapNotNull null
                        val offerToken = map["offerToken"] as? String ?: return@mapNotNull null
                        AndroidSubscriptionOfferInput(sku = sku, offerToken = offerToken)
                    } ?: emptyList()

                    val purchaseType = parsePurchaseType(typeStr)
                    val requestProps = buildRequestPurchaseProps(
                        type = purchaseType,
                        skus = skusNormalized,
                        obfuscatedAccountId = obfuscatedAccountId,
                        obfuscatedProfileId = obfuscatedProfileId,
                        isOfferPersonalized = isOfferPersonalized,
                        subscriptionOffers = offers,
                        purchaseTokenAndroid = purchaseTokenAndroid,
                        replacementModeAndroid = replacementModeAndroid,
                        developerBillingOption = developerBillingOption
                    )

                    iap.requestPurchase(requestProps)
                    // Success signaled by purchase-updated event
                    safe.success(null)
                } catch (e: Exception) {
                    safe.error(OpenIapError.PurchaseFailed.CODE, OpenIapError.PurchaseFailed.MESSAGE, e.message)
                }
            }
            }

            // -----------------------------------------------------------------
            // Android-suffix stable APIs (kept)
            // -----------------------------------------------------------------
            "getStorefront" -> {
                scope.launch {
                    try {
                        val iap = openIap ?: run {
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

            // Alternative Billing APIs
            "checkAlternativeBillingAvailabilityAndroid" -> {
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val isAvailable = iap.checkAlternativeBillingAvailability()
                        safe.success(isAvailable)
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "showAlternativeBillingDialogAndroid" -> {
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val act = activity
                        if (act == null) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, "Activity not available")
                            return@launch
                        }
                        val userAccepted = iap.showAlternativeBillingInformationDialog(act)
                        safe.success(userAccepted)
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "createAlternativeBillingTokenAndroid" -> {
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val token = iap.createAlternativeBillingReportingToken()
                        safe.success(token)
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }

            // Billing Programs API (8.2.0+)
            "isBillingProgramAvailableAndroid" -> {
                val programStr = call.argument<String>("program")
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val program = BillingProgramAndroid.fromJson(programStr ?: "unspecified")
                        val result = iap.isBillingProgramAvailable(program)
                        val response = JSONObject().apply {
                            put("billingProgram", result.billingProgram.toJson())
                            put("isAvailable", result.isAvailable)
                        }
                        safe.success(response.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "createBillingProgramReportingDetailsAndroid" -> {
                val programStr = call.argument<String>("program")
                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val program = BillingProgramAndroid.fromJson(programStr ?: "unspecified")
                        val result = iap.createBillingProgramReportingDetails(program)
                        val response = JSONObject().apply {
                            put("billingProgram", result.billingProgram.toJson())
                            put("externalTransactionToken", result.externalTransactionToken)
                        }
                        safe.success(response.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "launchExternalLinkAndroid" -> {
                val programStr = call.argument<String?>("billingProgram")
                val launchModeStr = call.argument<String?>("launchMode")
                val linkTypeStr = call.argument<String?>("linkType")
                val linkUri = call.argument<String?>("linkUri")

                scope.launch {
                    try {
                        val iap = openIap
                        if (iap == null) {
                            safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                            return@launch
                        }
                        val act = activity
                        if (act == null) {
                            safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, "Activity not available")
                            return@launch
                        }
                        if (linkUri.isNullOrBlank()) {
                            safe.error(OpenIapError.DeveloperError.CODE, "linkUri is required for launchExternalLinkAndroid", null)
                            return@launch
                        }
                        val launchParams = LaunchExternalLinkParamsAndroid(
                            billingProgram = BillingProgramAndroid.fromJson(programStr ?: "unspecified"),
                            launchMode = ExternalLinkLaunchModeAndroid.fromJson(launchModeStr ?: "unspecified"),
                            linkType = ExternalLinkTypeAndroid.fromJson(linkTypeStr ?: "unspecified"),
                            linkUri = linkUri
                        )
                        val success = iap.launchExternalLink(act, launchParams)
                        safe.success(success)
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }

            // Legacy/compat purchases queries
            "getAvailableItemsByType" -> {
                logDeprecated("getAvailableItemsByType", "Use getAvailableItems() instead")
                val typeStr = call.argument<String>("type") ?: "inapp"
                val reqType = parsePurchaseType(typeStr)
                scope.launch {
                    // Ensure connection for legacy path
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection(InitConnectionConfig()) ?: false
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
                        val arr = purchasesToJsonArray(purchases)
                        safe.success(arr.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }
            "getPurchaseHistoryByType" -> {
                logDeprecated("getPurchaseHistoryByType", "Use getAvailableItems() instead")
                val typeStr = call.argument<String>("type") ?: "inapp"
                val reqType = parsePurchaseType(typeStr)
                scope.launch {
                    // Ensure connection for legacy path
                    connectionMutex.withLock {
                        try {
                            attachListenersIfNeeded()
                            openIap?.setActivity(activity)
                            if (!connectionReady) {
                                val ok = openIap?.initConnection(InitConnectionConfig()) ?: false
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
                        // Note: As of v6.4.6+, getAvailablePurchases returns only active purchases on Android.
                        // Purchase history (including expired/consumed items) is not supported on Android
                        // by the OpenIAP library. The reqType parameter is preserved for backward compatibility
                        // but is not used. Apps should migrate to getAvailableItems() for active purchases.
                        val purchases = iap.getAvailablePurchases(null)
                        val arr = purchasesToJsonArray(purchases)
                        safe.success(arr.toString())
                    } catch (e: Exception) {
                        safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                    }
                }
            }

            // Legacy/compat purchase flow
            "buyItemByType" -> {
                logDeprecated("buyItemByType", "Use requestPurchase(params) instead")
                val typeStr = call.argument<String>("type")
                val productId = call.argument<String>("productId")
                    ?: call.argument<String>("sku")
                    ?: call.argument<ArrayList<String>>("skus")?.firstOrNull()
                val obfuscatedAccountId = call.argument<String>("obfuscatedAccountId")
                val obfuscatedProfileId = call.argument<String>("obfuscatedProfileId")
                val isOfferPersonalized = call.argument<Boolean>("isOfferPersonalized") ?: false

                if (productId.isNullOrBlank()) {
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
                                val ok = openIap?.initConnection(InitConnectionConfig()) ?: false
                                connectionReady = ok
                                val item = JSONObject().apply { put("connected", ok) }
                                channel?.invokeMethod("connection-updated", item.toString())
                                if (!ok) {
                                    safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                                    return@withLock
                                }
                            }
                        } catch (e: Exception) {
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
                        val skus = listOf(productId)
                        val purchaseType = parsePurchaseType(typeStr)
                        val requestProps = buildRequestPurchaseProps(
                            type = purchaseType,
                            skus = skus,
                            obfuscatedAccountId = obfuscatedAccountId,
                            obfuscatedProfileId = obfuscatedProfileId,
                            isOfferPersonalized = isOfferPersonalized,
                            subscriptionOffers = emptyList(),
                            purchaseTokenAndroid = null,
                            replacementModeAndroid = null
                        )

                        iap.requestPurchase(requestProps)
                        safe.success(null)
                    } catch (e: Exception) {
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

            // Verify Purchase (Platform-specific, v8.0.0+)
            "verifyPurchase" -> {
                val googleOptions = call.argument<Map<String, Any?>>("google")

                // Android only supports google options
                if (googleOptions == null) {
                    safe.error(OpenIapError.DeveloperError.CODE, "google options required for Android verification", null)
                    return
                }

                val sku = googleOptions["sku"] as? String
                val accessToken = googleOptions["accessToken"] as? String
                val packageName = googleOptions["packageName"] as? String
                val purchaseToken = googleOptions["purchaseToken"] as? String
                val isSub = googleOptions["isSub"] as? Boolean

                // Validate required fields (sensitive data check)
                if (accessToken.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, "accessToken is required for Google verification", null)
                    return
                }
                if (packageName.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, "packageName is required for Google verification", null)
                    return
                }
                if (purchaseToken.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, "purchaseToken is required for Google verification", null)
                    return
                }
                if (sku.isNullOrBlank()) {
                    safe.error(OpenIapError.DeveloperError.CODE, "sku is required for Google verification", null)
                    return
                }

                scope.launch {
                    withBillingReady(safe, autoInit = true) {
                        try {
                            val iap = openIap
                            if (iap == null) {
                                safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                                return@withBillingReady
                            }

                            // Build props for OpenIAP using new API structure
                            val propsMap = mapOf(
                                "google" to mapOf(
                                    "sku" to sku,
                                    "accessToken" to accessToken,
                                    "packageName" to packageName,
                                    "purchaseToken" to purchaseToken,
                                    "isSub" to isSub
                                )
                            )
                            val props = dev.hyo.openiap.VerifyPurchaseProps.fromJson(propsMap)
                            val result = iap.verifyPurchase(props)

                            // Convert result to JSON
                            val payload = JSONObject().apply {
                                put("__typename", "VerifyPurchaseResultAndroid")
                                // Add Android-specific result fields from OpenIAP result
                                when (result) {
                                    is dev.hyo.openiap.VerifyPurchaseResultAndroid -> {
                                        put("autoRenewing", result.autoRenewing)
                                        put("betaProduct", result.betaProduct)
                                        result.cancelDate?.let { put("cancelDate", it) }
                                        result.cancelReason?.let { put("cancelReason", it) }
                                        result.deferredDate?.let { put("deferredDate", it) }
                                        result.deferredSku?.let { put("deferredSku", it) }
                                        put("freeTrialEndDate", result.freeTrialEndDate)
                                        put("gracePeriodEndDate", result.gracePeriodEndDate)
                                        put("parentProductId", result.parentProductId)
                                        put("productId", result.productId)
                                        put("productType", result.productType)
                                        put("purchaseDate", result.purchaseDate)
                                        put("quantity", result.quantity)
                                        put("receiptId", result.receiptId)
                                        put("renewalDate", result.renewalDate)
                                        put("term", result.term)
                                        put("termSku", result.termSku)
                                        put("testTransaction", result.testTransaction)
                                    }
                                    else -> {
                                        OpenIapLog.w(TAG, "Unexpected verification result type: ${result::class.simpleName}")
                                    }
                                }
                            }
                            safe.success(payload.toString())
                        } catch (e: Exception) {
                            OpenIapLog.e("verifyPurchase error", e)
                            safe.error(OpenIapError.VerificationFailed.CODE, "Verification failed: ${e.message}", null)
                        }
                    }
                }
            }

            // Verify Purchase with Provider (IAPKit)
            "verifyPurchaseWithProvider" -> {
                val params = call.arguments as? Map<*, *>
                val provider = params?.get("provider") as? String

                if (provider == null) {
                    safe.error(OpenIapError.DeveloperError.CODE, "provider required", null)
                    return
                }

                scope.launch {
                    withBillingReady(safe, autoInit = true) {
                        try {
                            val iap = openIap
                            if (iap == null) {
                                safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "IAP module not initialized.")
                                return@withBillingReady
                            }

                            // Build props map for OpenIAP
                            val propsMap = mutableMapOf<String, Any?>("provider" to provider)
                            (params["iapkit"] as? Map<*, *>)?.let { iapkit ->
                                val iapkitMap = mutableMapOf<String, Any?>()
                                (iapkit["apiKey"] as? String)?.let { iapkitMap["apiKey"] = it }
                                ((iapkit["google"] as? Map<*, *>)?.get("purchaseToken") as? String)?.let { purchaseToken ->
                                    iapkitMap["google"] = mapOf("purchaseToken" to purchaseToken)
                                }
                                ((iapkit["apple"] as? Map<*, *>)?.get("jws") as? String)?.let { jws ->
                                    iapkitMap["apple"] = mapOf("jws" to jws)
                                }
                                propsMap["iapkit"] = iapkitMap
                            }

                            val props = dev.hyo.openiap.VerifyPurchaseWithProviderProps.fromJson(propsMap)
                            val result = iap.verifyPurchaseWithProvider(props)

                            // Convert result to JSON
                            val iapkitResult = result.iapkit?.let { item ->
                                JSONObject().apply {
                                    put("isValid", item.isValid)
                                    put("state", item.state.toJson())
                                    put("store", item.store.toJson())
                                }
                            }
                            val payload = JSONObject().apply {
                                put("provider", result.provider.toJson())
                                if (iapkitResult != null) {
                                    put("iapkit", iapkitResult)
                                }
                            }
                            safe.success(payload.toString())
                        } catch (e: Exception) {
                            OpenIapLog.e("verifyPurchaseWithProvider error", e)
                            safe.error(OpenIapError.VerificationFailed.CODE, "Verification failed: ${e.message}", null)
                        }
                    }
                }
            }

            else -> safe.notImplemented()
        }
    }

    @Deprecated("Deprecated channel endpoint; will be removed in 7.0.0")
    private fun logDeprecated(name: String, message: String) {
        OpenIapLog.w(TAG, "[$name] is deprecated and will be removed in 7.0.0. $message")
    }

    /**
     * Ensures billing client is ready before executing a block of code.
     * This helper reduces duplication of connection checking logic.
     *
     * @param autoInit If true, automatically initializes connection if not ready
     */
    private suspend fun withBillingReady(
        safe: MethodResultWrapper,
        autoInit: Boolean = false,
        block: suspend () -> Unit
    ) {
        connectionMutex.withLock {
            try {
                attachListenersIfNeeded()
                openIap?.setActivity(activity)
                if (!connectionReady) {
                    if (autoInit) {
                        val ok = openIap?.initConnection(InitConnectionConfig()) ?: false
                        connectionReady = ok
                        val item = JSONObject().apply { put("connected", ok) }
                        channel?.invokeMethod("connection-updated", item.toString())
                        if (!ok) {
                            safe.error(OpenIapError.InitConnection.CODE, OpenIapError.InitConnection.MESSAGE, "Failed to initialize connection")
                            return
                        }
                    } else {
                        safe.error(OpenIapError.NotPrepared.CODE, OpenIapError.NotPrepared.MESSAGE, "Billing not ready")
                        return
                    }
                }
            } catch (e: Exception) {
                safe.error(OpenIapError.BillingError.CODE, OpenIapError.BillingError.MESSAGE, e.message)
                return
            }
        }
        block()
    }

    private fun attachListenersIfNeeded() {
        if (listenersAttached) return
        listenersAttached = true
        openIap?.addPurchaseUpdateListener(OpenIapPurchaseUpdateListener { p ->
            scope.launch {
                try {
                    val payload = JSONObject(p.toJson())
                    channel?.invokeMethod("purchase-updated", payload.toString())
                } catch (e: Exception) {
                    OpenIapLog.e("Failed to send purchase-updated", e)
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
                    OpenIapLog.e("Failed to send purchase-error", ex)
                }
            }
        })
        openIap?.addUserChoiceBillingListener { details ->
            scope.launch {
                try {
                    val payload = JSONObject(details.toJson())
                    channel?.invokeMethod("user-choice-billing-android", payload.toString())
                } catch (e: Exception) {
                    OpenIapLog.e("Failed to send user-choice-billing-android", e)
                }
            }
        }
        openIap?.addDeveloperProvidedBillingListener(OpenIapDeveloperProvidedBillingListener { details ->
            scope.launch {
                try {
                    val payload = JSONObject(details.toJson())
                    channel?.invokeMethod("developer-provided-billing-android", payload.toString())
                } catch (e: Exception) {
                    OpenIapLog.e("Failed to send developer-provided-billing-android", e)
                }
            }
        })
    }

    companion object {
        private const val TAG = "InappPurchasePlugin"
        private const val PLAY_STORE_URL = "https://play.google.com/store/account/subscriptions"

        private const val KEY_REQUEST_SUBSCRIPTION = "requestSubscription"
        private const val KEY_REQUEST_PURCHASE = "requestPurchase"
        private const val KEY_ANDROID = "android"
        private const val KEY_TYPE = "type"
        private const val KEY_SKUS = "skus"
        private const val KEY_IS_OFFER_PERSONALIZED = "isOfferPersonalized"
        private const val KEY_OBFUSCATED_ACCOUNT = "obfuscatedAccountIdAndroid"
        private const val KEY_OBFUSCATED_PROFILE = "obfuscatedProfileIdAndroid"
        private const val KEY_PURCHASE_TOKEN = "purchaseTokenAndroid"
        private const val KEY_REPLACEMENT_MODE = "replacementModeAndroid"
        private const val KEY_SUBSCRIPTION_OFFERS = "subscriptionOffers"
        private const val KEY_DEVELOPER_BILLING_OPTION = "developerBillingOption"
    }
}
