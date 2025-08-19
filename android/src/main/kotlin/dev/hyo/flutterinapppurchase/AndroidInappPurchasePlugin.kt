package dev.hyo.flutterinapppurchase

import android.app.Activity
import android.app.Application
import android.app.Application.ActivityLifecycleCallbacks
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import com.android.billingclient.api.*
import com.android.billingclient.api.BillingFlowParams.*
import io.flutter.plugin.common.FlutterException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * AndroidInappPurchasePlugin
 */
class AndroidInappPurchasePlugin internal constructor() : MethodCallHandler,
    ActivityLifecycleCallbacks {
    private var safeResult: MethodResultWrapper? = null
    private var billingClient: BillingClient? = null
    private var context: Context? = null
    private var activity: Activity? = null
    private var channel: MethodChannel? = null
    fun setContext(context: Context?) {
        this.context = context
    }
    fun setActivity(activity: Activity?) {
        this.activity = activity
        Log.d(TAG, "Activity set: ${if (activity != null) "not null" else "null"}")
    }
    fun setChannel(channel: MethodChannel?) {
        this.channel = channel
        Log.d(TAG, "Channel set: ${if (channel != null) "not null" else "null"}")
    }
    fun onDetachedFromActivity() {
        endBillingClientConnection()
    }
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityResumed(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityDestroyed(activity: Activity) {
        if (this.activity === activity && context != null) {
            (context as Application?)!!.unregisterActivityLifecycleCallbacks(this)
            endBillingClientConnection()
        }
    }
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        if(call.method == "getStore"){
            result.success(FlutterInappPurchasePlugin.getStore())
            return
        }

        if(call.method == "manageSubscription"){
            result.success(manageSubscription(call.argument<String>("sku")!!,call.argument<String>("packageName")!!))
            return
        }

        if(call.method == "openPlayStoreSubscriptions"){
            result.success(openPlayStoreSubscriptions())
            return
        }

        safeResult = MethodResultWrapper(result, channel!!)
        val safeChannel = MethodResultWrapper(result, channel!!)

        if (call.method == "initConnection") {
            if (billingClient != null) {
                safeChannel.success("Already started. Call endConnection method if you want to start over.")
                return
            }
            
            Log.d(TAG, "Creating BillingClient with PurchasesUpdatedListener")
            billingClient = BillingClient.newBuilder(context ?: return)
                .setListener(purchasesUpdatedListener)
                .enablePendingPurchases(
                    PendingPurchasesParams.newBuilder()
                        .enableOneTimeProducts()
                        .build()
                )
                .build()
            Log.d(TAG, "BillingClient created successfully")
            
            billingClient?.startConnection(object : BillingClientStateListener {
                private var alreadyFinished = false
            
                override fun onBillingSetupFinished(billingResult: BillingResult) {
                    if (alreadyFinished) return
                    alreadyFinished = true
            
                    try {
                        val isConnected = billingResult.responseCode == BillingClient.BillingResponseCode.OK
                        updateConnectionStatus(isConnected)
            
                        val resultMessage = if (isConnected) {
                            "Billing client ready"
                        } else {
                            "responseCode: ${billingResult.responseCode}"
                        }
            
                        if (isConnected) {
                            safeChannel.success(resultMessage)
                        } else {
                            safeChannel.error(call.method, resultMessage, "")
                        }
                    } catch (je: JSONException) {
                        je.printStackTrace()
                    }
                }
            
                override fun onBillingServiceDisconnected() {
                    if (alreadyFinished) return
                    alreadyFinished = true
                    updateConnectionStatus(false)
                }
            
                private fun updateConnectionStatus(isConnected: Boolean) {
                    try {
                        val item = JSONObject().apply {
                            put("connected", isConnected)
                        }
                        safeChannel.invokeMethod("connection-updated", item.toString())
                    } catch (je: JSONException) {
                        je.printStackTrace()
                    }
                }
            })
            return
        }

        if (call.method == "endConnection") {
            if (billingClient == null) {
                safeChannel.success("Already ended.")
            }else{
                endBillingClientConnection(safeChannel)
            }
            return
        }

        val isReady = billingClient?.isReady

        if(call.method == "isReady"){
            safeChannel.success(isReady)
            return
        }

        if (isReady != true) {
            safeChannel.error(
                call.method,
                BillingError.E_NOT_PREPARED,
                "IAP not prepared. Check if Google Play service is available."
            )
            return
        }

        when(call.method){
            "showInAppMessages" -> showInAppMessages(safeChannel)
            "getProducts" -> getProductsByType(BillingClient.ProductType.INAPP, call, safeChannel)
            "getSubscriptions" -> getProductsByType(BillingClient.ProductType.SUBS, call, safeChannel)
            "getAvailableItemsByType" -> getAvailableItemsByType(call, safeChannel)
            "getPurchaseHistoryByType" -> getPurchaseHistoryByType(call, safeChannel)
            "buyItemByType" -> buyProduct(call, safeChannel)
            "acknowledgePurchase" -> acknowledgePurchase(call, safeChannel)
            "consumeProduct" -> consumeProduct(call, safeChannel)
            "consumePurchase" -> consumeProduct(call, safeChannel)
            else -> safeChannel.notImplemented()
        }
    }

    private fun manageSubscription(sku: String, packageName: String): Boolean{
        val url = "$PLAY_STORE_URL?sku=${sku}&package=${packageName}"
        return openWithFallback(Uri.parse(url))
    }

    private fun openPlayStoreSubscriptions():Boolean{
        return openWithFallback(Uri.parse(PLAY_STORE_URL))
    }

    private fun openWithFallback(uri: Uri):Boolean{
        try{
            activity!!.startActivity(Intent(Intent.ACTION_VIEW).apply { data = uri })
            return true
        }catch (e: ActivityNotFoundException){
            try{
                activity!!.startActivity( Intent(Intent.ACTION_VIEW)
                    .setDataAndType(uri, "text/html")
                    .addCategory(Intent.CATEGORY_BROWSABLE))
                return true
            }catch (e: ActivityNotFoundException){
                // ignore
            }
        }
        return false
    }

    private fun showInAppMessages(safeChannel: MethodResultWrapper) {
        val inAppMessageParams = InAppMessageParams.newBuilder()
            .addInAppMessageCategoryToShow(InAppMessageParams.InAppMessageCategoryId.TRANSACTIONAL)
            .build()

        billingClient!!.showInAppMessages(activity!!, inAppMessageParams) { inAppMessageResult ->
            safeChannel.invokeMethod("on-in-app-message", inAppMessageResult.responseCode)
        }
        safeChannel.success("show in app messages ready")
    }


    private fun getAvailableItemsByType(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val type = if(call.argument<String>("type") == "subs") BillingClient.ProductType.SUBS else BillingClient.ProductType.INAPP
        val params = QueryPurchasesParams.newBuilder().apply { setProductType(type) }.build()
        val items = JSONArray()
        billingClient!!.queryPurchasesAsync(params) { billingResult, productDetailList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                for (purchase in productDetailList) {
                    val item = JSONObject()
                    item.put("id", purchase.orderId)
                    item.put("productId", purchase.products[0])
                    item.put("ids", JSONArray(purchase.products))
                    item.put("transactionId", purchase.orderId)  // @deprecated - use id instead
                    item.put("transactionDate", purchase.purchaseTime)
                    item.put("transactionReceipt", purchase.originalJson)
                    item.put("purchaseToken", purchase.purchaseToken)  // Unified field
                    item.put("purchaseTokenAndroid", purchase.purchaseToken)  // Deprecated - use purchaseToken
                    item.put("dataAndroid", purchase.originalJson)
                    item.put("signatureAndroid", purchase.signature)
                    item.put("purchaseStateAndroid", purchase.purchaseState)
                    item.put("packageNameAndroid", purchase.packageName)
                    item.put("developerPayloadAndroid", purchase.developerPayload)
                    item.put("platform", "android")
                    if (type == BillingClient.ProductType.INAPP) {
                        item.put("isAcknowledgedAndroid", purchase.isAcknowledged)
                    } else if (type == BillingClient.ProductType.SUBS) {
                        item.put("autoRenewingAndroid", purchase.isAutoRenewing)
                    }
                    val accountIdentifiers = purchase.accountIdentifiers
                    if (accountIdentifiers != null) {
                        item.put("obfuscatedAccountIdAndroid", accountIdentifiers.obfuscatedAccountId)
                        item.put("obfuscatedProfileIdAndroid", accountIdentifiers.obfuscatedProfileId)
                    }
                    items.put(item)
                }
                safeChannel.success(items.toString())
            } else {
                safeChannel.error(
                    call.method, billingResult.debugMessage,
                    "responseCode:${billingResult.responseCode}"
                )
            }
        }
    }

    private fun consumeProduct(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val token = call.argument<String>("purchaseToken")
        val params = ConsumeParams.newBuilder()
            .setPurchaseToken(token!!)
            .build()
        billingClient!!.consumeAsync(params) { billingResult, purchaseToken ->
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                safeChannel.error(call.method, errorData.code, errorData.message)
                return@consumeAsync
            }
            try {
                val item = JSONObject()
                item.put("responseCode", billingResult.responseCode)
                item.put("debugMessage", billingResult.debugMessage)
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                item.put("code", errorData.code)
                item.put("message", errorData.message)
                item.put("purchaseToken", purchaseToken)
                safeChannel.success(item.toString())
                return@consumeAsync
            } catch (je: JSONException) {
                safeChannel.error(
                    TAG,
                    BillingError.E_BILLING_RESPONSE_JSON_PARSE_ERROR,
                    je.message
                )
                return@consumeAsync
            }
        }
    }

    private fun acknowledgePurchase(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val token = call.argument<String>("purchaseToken")
        val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(token!!)
            .build()
        billingClient!!.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                safeChannel.error(call.method, errorData.code, errorData.message)
                return@acknowledgePurchase
            }
            try {
                val item = JSONObject()
                item.put("responseCode", billingResult.responseCode)
                item.put("debugMessage", billingResult.debugMessage)
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                item.put("code", errorData.code)
                item.put("message", errorData.message)
                safeChannel.success(item.toString())
            } catch (je: JSONException) {
                je.printStackTrace()
                safeChannel.error(
                    TAG,
                    BillingError.E_BILLING_RESPONSE_JSON_PARSE_ERROR,
                    je.message
                )
            }
        }
    }

    private fun getPurchaseHistoryByType(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val type = if(call.argument<String>("type") == "subs") BillingClient.ProductType.SUBS else BillingClient.ProductType.INAPP
        val params = QueryPurchaseHistoryParams.newBuilder().apply { setProductType(type) }.build()

        // Note: queryPurchaseHistoryAsync was removed in v8.0.0
        // Using queryPurchasesAsync instead
        val queryParams = QueryPurchasesParams.newBuilder()
            .setProductType(type)
            .build()
            
        billingClient!!.queryPurchasesAsync(
            queryParams
        ) { billingResult, purchasesList ->
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                safeChannel.error(call.method, errorData.code, errorData.message)
                return@queryPurchasesAsync
            }
            val items = JSONArray()
            try {
                for (purchase in purchasesList) {
                    val item = JSONObject()
                    item.put("id", purchase.orderId)
                    item.put("productId", purchase.products[0])
                    item.put("ids", JSONArray(purchase.products))
                    item.put("transactionId", purchase.orderId)  // @deprecated - use id instead
                    item.put("transactionDate", purchase.purchaseTime)
                    item.put("transactionReceipt", purchase.originalJson)
                    item.put("purchaseToken", purchase.purchaseToken)  // Unified field
                    item.put("purchaseTokenAndroid", purchase.purchaseToken)  // Deprecated - use purchaseToken
                    item.put("dataAndroid", purchase.originalJson)
                    item.put("signatureAndroid", purchase.signature)
                    item.put("purchaseStateAndroid", purchase.purchaseState)
                    item.put("autoRenewingAndroid", purchase.isAutoRenewing)
                    item.put("isAcknowledgedAndroid", purchase.isAcknowledged)
                    item.put("packageNameAndroid", purchase.packageName)
                    item.put("developerPayloadAndroid", purchase.developerPayload)
                    item.put("platform", "android")
                    val accountIdentifiers = purchase.accountIdentifiers
                    if (accountIdentifiers != null) {
                        item.put("obfuscatedAccountIdAndroid", accountIdentifiers.obfuscatedAccountId)
                        item.put("obfuscatedProfileIdAndroid", accountIdentifiers.obfuscatedProfileId)
                    }
                    items.put(item)
                }
                safeChannel.success(items.toString())
                return@queryPurchasesAsync
            } catch (je: JSONException) {
                je.printStackTrace()
                safeChannel.error(TAG, BillingError.E_BILLING_RESPONSE_JSON_PARSE_ERROR, je.message)
            }
        }
    }

    private fun getProductsByType(
        productType: String,
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        val productIds : ArrayList<String> = call.argument<ArrayList<String>>("productIds")!!
        val params = ArrayList<QueryProductDetailsParams.Product>()
        for (i in productIds.indices) {
            params.add(QueryProductDetailsParams.Product.newBuilder().setProductId(productIds[i]).setProductType(productType).build())
        }

        billingClient!!.queryProductDetailsAsync(
            QueryProductDetailsParams.newBuilder().setProductList(params).build()
        ) { billingResult: BillingResult, productDetailsResult: QueryProductDetailsResult ->
            // On error
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                safeChannel.error(call.method, errorData.code, errorData.message)
                return@queryProductDetailsAsync
            }

            try {
                val products = productDetailsResult.productDetailsList ?: emptyList()
                val items = JSONArray()
                for (productDetails in products) {
                    // Add to list of tracked products
                    if (!productDetailsList.contains(productDetails)) {
                        productDetailsList.add(productDetails)
                    }

                    // Create flutter objects
                    val item = JSONObject()
                    item.put("id", productDetails.productId)
                    item.put("productId", productDetails.productId)
                    item.put("type", productDetails.productType)
                    item.put("title", productDetails.title)
                    item.put("displayName", productDetails.name)
                    item.put("description", productDetails.description)
                    item.put("platform", "android")
                    
                    // Set currency and displayPrice based on product type
                    val currency = productDetails.oneTimePurchaseOfferDetails?.priceCurrencyCode
                        ?: productDetails.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.priceCurrencyCode
                        ?: "Unknown"
                    val displayPrice = productDetails.oneTimePurchaseOfferDetails?.formattedPrice
                        ?: productDetails.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.formattedPrice
                        ?: "N/A"
                    
                    item.put("currency", currency)
                    item.put("displayPrice", displayPrice)

                    // One-time offer details have changed in 5.0
                    if (productDetails.oneTimePurchaseOfferDetails != null) {
                        item.put("introductoryPrice", productDetails.oneTimePurchaseOfferDetails!!.formattedPrice)
                    }

                    if (productDetails.productType == BillingClient.ProductType.INAPP) {
                        val oneTimePurchaseOfferDetails = productDetails.oneTimePurchaseOfferDetails

                        if (oneTimePurchaseOfferDetails != null) {
                            item.put("price", (oneTimePurchaseOfferDetails.priceAmountMicros / 1000000f).toString())
                            item.put("localizedPrice", oneTimePurchaseOfferDetails.formattedPrice)
                            
                            // Add structured oneTimePurchaseOfferDetails
                            val offerDetails = JSONObject()
                            offerDetails.put("priceCurrencyCode", oneTimePurchaseOfferDetails.priceCurrencyCode)
                            offerDetails.put("formattedPrice", oneTimePurchaseOfferDetails.formattedPrice)
                            offerDetails.put("priceAmountMicros", oneTimePurchaseOfferDetails.priceAmountMicros.toString())
                            item.put("oneTimePurchaseOfferDetails", offerDetails)
                        }
                    } else if (productDetails.productType == BillingClient.ProductType.SUBS) {
                        // These generalized values are derived from the first pricing object, mainly for backwards compatibility
                        // It would be better to use the actual objects in PricingPhases and SubscriptionOffers
    
                        // Get first subscription offer
                        val firstOffer = productDetails.subscriptionOfferDetails?.firstOrNull()
                        if (firstOffer != null && firstOffer.pricingPhases.pricingPhaseList.isNotEmpty()) {
                            val defaultPricingPhase = firstOffer.pricingPhases.pricingPhaseList[0]
                            item.put("price", (defaultPricingPhase.priceAmountMicros / 1000000f).toString())
                            item.put("localizedPrice", defaultPricingPhase.formattedPrice)
                            item.put("subscriptionPeriodAndroid", defaultPricingPhase.billingPeriod)
                        }
    
                        // Add structured subscriptionOfferDetails
                        val subsOffers = JSONArray()
                        if (productDetails.subscriptionOfferDetails != null) {
                            for (offer in productDetails.subscriptionOfferDetails!!) {
                                val offerItem = JSONObject()
                                offerItem.put("basePlanId", offer.basePlanId)
                                offerItem.put("offerId", offer.offerId)
                                offerItem.put("offerToken", offer.offerToken)
                                offerItem.put("offerTags", JSONArray(offer.offerTags))
                                
                                // Add pricingPhases
                                val pricingPhasesObj = JSONObject()
                                val pricingPhasesList = JSONArray()
                                for (pricing in offer.pricingPhases.pricingPhaseList) {
                                    val pricingPhase = JSONObject()
                                    pricingPhase.put("formattedPrice", pricing.formattedPrice)
                                    pricingPhase.put("priceCurrencyCode", pricing.priceCurrencyCode)
                                    pricingPhase.put("billingPeriod", pricing.billingPeriod)
                                    pricingPhase.put("billingCycleCount", pricing.billingCycleCount)
                                    pricingPhase.put("priceAmountMicros", pricing.priceAmountMicros.toString())
                                    pricingPhase.put("recurrenceMode", pricing.recurrenceMode)
                                    pricingPhasesList.put(pricingPhase)
                                }
                                pricingPhasesObj.put("pricingPhaseList", pricingPhasesList)
                                offerItem.put("pricingPhases", pricingPhasesObj)
                                subsOffers.put(offerItem)
                            }
                        }
                        item.put("subscriptionOfferDetails", subsOffers)
                    }

                    items.put(item)
                }
                safeChannel.success(items.toString())
                return@queryProductDetailsAsync
            } catch (je: JSONException) {
                je.printStackTrace()
                safeChannel.error(TAG, BillingError.E_BILLING_RESPONSE_JSON_PARSE_ERROR, je.message)
            } catch (fe: FlutterException) {
                safeChannel.error(call.method, fe.message, fe.localizedMessage)
                return@queryProductDetailsAsync
            }
        }
    }

    private fun buyProduct(
        call: MethodCall,
        safeChannel: MethodResultWrapper
    ) {
        Log.d(TAG, "buyProduct called with arguments: ${call.arguments}")
        try {
            val type = if(call.argument<String>("type") == "subs") BillingClient.ProductType.SUBS else BillingClient.ProductType.INAPP
            val obfuscatedAccountId = call.argument<String>("obfuscatedAccountId")
            val obfuscatedProfileId = call.argument<String>("obfuscatedProfileId")
            val productId = call.argument<String>("productId")
            val prorationMode = call.argument<Int>("prorationMode")!!
            val purchaseToken = call.argument<String>("purchaseToken")
            val offerTokenIndex = call.argument<Int>("offerTokenIndex")
            
            Log.d(TAG, "buyProduct - productId: $productId, type: $type")
            val builder = newBuilder()
            var selectedProductDetails: ProductDetails? = null
            for (productDetails in productDetailsList) {
                if (productDetails.productId == productId) {
                    selectedProductDetails = productDetails
                    break
                }
            }
            if (selectedProductDetails == null) {
                val debugMessage =
                    "The selected product was not found. Please fetch products first by calling getItems"
                
                // Send purchase-error event like expo-iap
                try {
                    val errorJson = JSONObject()
                    errorJson.put("code", "E_PRODUCT_NOT_FOUND")
                    errorJson.put("message", debugMessage)
                    errorJson.put("productId", productId)
                    
                    Log.d(TAG, "Sending purchase-error event for product not found")
                    channel?.invokeMethod("purchase-error", errorJson.toString())
                } catch (je: JSONException) {
                    Log.e(TAG, "Failed to create error JSON: ${je.message}")
                }
                
                safeChannel.error(TAG, "E_PRODUCT_NOT_FOUND", debugMessage)
                return
            }

            // Get the selected offerToken from the product, or first one if this is a migrated from 4.0 product
            // or if the offerTokenIndex was not provided
            val productDetailsParamsBuilder = ProductDetailsParams.newBuilder().setProductDetails(selectedProductDetails)
            var offerToken : String? = null

            if (type == BillingClient.ProductType.SUBS) {
                if (offerTokenIndex != null) {
                    offerToken = selectedProductDetails.subscriptionOfferDetails?.get(offerTokenIndex)?.offerToken
                }
                if (offerToken == null) {
                    offerToken = selectedProductDetails.subscriptionOfferDetails!![0].offerToken
                }

                productDetailsParamsBuilder.setOfferToken(offerToken)
            }

            val productDetailsParamsList = listOf(productDetailsParamsBuilder.build())

            builder.setProductDetailsParamsList(productDetailsParamsList)

            val params = SubscriptionUpdateParams.newBuilder()

            if (obfuscatedAccountId != null) {
                builder.setObfuscatedAccountId(obfuscatedAccountId)
            }
            if (obfuscatedProfileId != null) {
                builder.setObfuscatedProfileId(obfuscatedProfileId)
            }

            when (prorationMode) {
                -1 -> {} //ignore
                BillingFlowParams.SubscriptionUpdateParams.ReplacementMode.CHARGE_PRORATED_PRICE -> {
                    params.setOldPurchaseToken(purchaseToken ?: "")
                        .setSubscriptionReplacementMode(BillingFlowParams.SubscriptionUpdateParams.ReplacementMode.CHARGE_PRORATED_PRICE)
                    builder.setSubscriptionUpdateParams(params.build())
                    if (type != BillingClient.ProductType.SUBS) {
                        safeChannel.error(
                            TAG,
                            "buyItemByType",
                            "IMMEDIATE_AND_CHARGE_PRORATED_PRICE for proration mode only works in subscription purchase."
                        )
                        return
                    }
                }
                1 -> { // IMMEDIATE_WITHOUT_PRORATION
                    params.setOldPurchaseToken(purchaseToken ?: "")
                        .setSubscriptionReplacementMode(BillingFlowParams.SubscriptionUpdateParams.ReplacementMode.WITHOUT_PRORATION)
                    builder.setSubscriptionUpdateParams(params.build())
                }
                4 -> { // DEFERRED
                    params.setOldPurchaseToken(purchaseToken ?: "")
                        .setSubscriptionReplacementMode(BillingFlowParams.SubscriptionUpdateParams.ReplacementMode.DEFERRED)
                    builder.setSubscriptionUpdateParams(params.build())
                }
                2 -> { // IMMEDIATE_WITH_TIME_PRORATION
                    params.setOldPurchaseToken(purchaseToken ?: "")
                        .setSubscriptionReplacementMode(BillingFlowParams.SubscriptionUpdateParams.ReplacementMode.WITH_TIME_PRORATION)
                    builder.setSubscriptionUpdateParams(params.build())
                }
                5 -> { // IMMEDIATE_AND_CHARGE_FULL_PRICE
                    params.setOldPurchaseToken(purchaseToken ?: "")
                        .setSubscriptionReplacementMode(BillingFlowParams.SubscriptionUpdateParams.ReplacementMode.CHARGE_FULL_PRICE)
                    builder.setSubscriptionUpdateParams(params.build())
                }
                else -> {
                    params.setOldPurchaseToken(purchaseToken ?: "")
                        .setSubscriptionReplacementMode(BillingFlowParams.SubscriptionUpdateParams.ReplacementMode.UNKNOWN_REPLACEMENT_MODE)
                    builder.setSubscriptionUpdateParams(params.build())
                }
            }
            if (activity != null) {
                Log.d(TAG, "Launching billing flow for product: $productId")
                val billingFlowParams = builder.build()
                val responseCode = billingClient!!.launchBillingFlow(activity!!, billingFlowParams)
                Log.d(TAG, "launchBillingFlow response code: ${responseCode.responseCode}")
                if (responseCode.responseCode != BillingClient.BillingResponseCode.OK) {
                    Log.e(TAG, "launchBillingFlow failed with code: ${responseCode.responseCode}, message: ${responseCode.debugMessage}")
                    val errorData = BillingError.getErrorFromResponseData(responseCode.responseCode)
                    
                    // Send purchase-error event like expo-iap
                    try {
                        val errorJson = JSONObject()
                        errorJson.put("responseCode", responseCode.responseCode)
                        errorJson.put("debugMessage", responseCode.debugMessage)
                        errorJson.put("code", errorData.code)
                        errorJson.put("message", errorData.message)
                        errorJson.put("productId", productId)
                        
                        Log.d(TAG, "Sending purchase-error event for launchBillingFlow failure")
                        channel?.invokeMethod("purchase-error", errorJson.toString())
                    } catch (je: JSONException) {
                        Log.e(TAG, "Failed to create error JSON: ${je.message}")
                    }
                    
                    safeChannel.error(TAG, errorData.code, "Failed to launch billing flow: ${errorData.message}")
                } else {
                    // Return success immediately - purchase result will come via purchasesUpdatedListener
                    safeChannel.success("Billing flow launched successfully")
                    Log.d(TAG, "Billing flow launched, purchase result will be sent via purchase-updated event")
                }
            } else {
                Log.e(TAG, "Activity is null, cannot launch billing flow")
                safeChannel.error(TAG, "E_ACTIVITY_NULL", "Activity is null, cannot launch billing flow")
            }
        } catch (e: Exception) {
            safeChannel.error(TAG, "buyItemByType", e.message)
            return
        }
    }

    private val purchasesUpdatedListener = PurchasesUpdatedListener { billingResult, purchases ->
        Log.d(TAG, "PurchasesUpdatedListener triggered!")
        Log.d(TAG, "BillingResult responseCode: ${billingResult.responseCode}")
        Log.d(TAG, "Purchases: ${purchases?.size ?: 0} items")
        
        try {
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                Log.d(TAG, "Purchase failed with response code: ${billingResult.responseCode}")
                val json = JSONObject()
                json.put("responseCode", billingResult.responseCode)
                json.put("debugMessage", billingResult.debugMessage)
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                json.put("code", errorData.code)
                json.put("message", errorData.message)
                Log.d(TAG, "Sending purchase-error event to Flutter, channel is ${if (channel != null) "not null" else "null"}")
                Log.d(TAG, "Error data: ${json.toString()}")
                if (channel != null) {
                    channel!!.invokeMethod("purchase-error", json.toString())
                    Log.d(TAG, "Successfully sent purchase-error event")
                } else {
                    Log.e(TAG, "Cannot send purchase-error event: channel is null!")
                }
                return@PurchasesUpdatedListener
            }
            if (purchases != null) {
                Log.d(TAG, "Processing ${purchases.size} successful purchases")
                for (purchase in purchases) {
                    Log.d(TAG, "Processing purchase: productId=${purchase.products[0]}, orderId=${purchase.orderId}")
                    val item = JSONObject()
                    item.put("id", purchase.orderId)
                    item.put("productId", purchase.products[0])
                    item.put("ids", JSONArray(purchase.products))
                    item.put("transactionId", purchase.orderId)  // @deprecated - use id instead
                    item.put("transactionDate", purchase.purchaseTime)
                    item.put("transactionReceipt", purchase.originalJson)
                    item.put("purchaseToken", purchase.purchaseToken)  // Unified field for iOS JWS and Android purchaseToken
                    item.put("purchaseTokenAndroid", purchase.purchaseToken)  // Deprecated - use purchaseToken
                    item.put("dataAndroid", purchase.originalJson)
                    item.put("signatureAndroid", purchase.signature)
                    item.put("purchaseStateAndroid", purchase.purchaseState)
                    item.put("autoRenewingAndroid", purchase.isAutoRenewing)
                    item.put("isAcknowledgedAndroid", purchase.isAcknowledged)
                    item.put("packageNameAndroid", purchase.packageName)
                    item.put("developerPayloadAndroid", purchase.developerPayload)
                    item.put("platform", "android")
                    val accountIdentifiers = purchase.accountIdentifiers
                    if (accountIdentifiers != null) {
                        item.put("obfuscatedAccountIdAndroid", accountIdentifiers.obfuscatedAccountId)
                        item.put("obfuscatedProfileIdAndroid", accountIdentifiers.obfuscatedProfileId)
                    }
                    Log.d(TAG, "Sending purchase-updated event to Flutter, channel is ${if (channel != null) "not null" else "null"}")
                    Log.d(TAG, "Purchase data: ${item.toString()}")
                    if (channel != null) {
                        channel!!.invokeMethod("purchase-updated", item.toString())
                        Log.d(TAG, "Successfully sent purchase-updated event")
                    } else {
                        Log.e(TAG, "Cannot send purchase-updated event: channel is null!")
                    }
                    return@PurchasesUpdatedListener
                }
            } else {
                val json = JSONObject()
                json.put("responseCode", billingResult.responseCode)
                json.put("debugMessage", billingResult.debugMessage)
                val errorData = BillingError.getErrorFromResponseData(billingResult.responseCode)
                json.put("code", errorData.code)
                json.put("message", "purchases returns null.")
                Log.d(TAG, "Sending purchase-error event to Flutter, channel is ${if (channel != null) "not null" else "null"}")
                Log.d(TAG, "Error data: ${json.toString()}")
                if (channel != null) {
                    channel!!.invokeMethod("purchase-error", json.toString())
                    Log.d(TAG, "Successfully sent purchase-error event")
                } else {
                    Log.e(TAG, "Cannot send purchase-error event: channel is null!")
                }
                return@PurchasesUpdatedListener
            }
        } catch (je: JSONException) {
            channel?.invokeMethod("purchase-error", je.message)
            return@PurchasesUpdatedListener
        }
    }

    private fun endBillingClientConnection(safeChannel: MethodResultWrapper? = null) {
        try {
            billingClient?.endConnection()
            billingClient = null
            safeChannel?.success("Billing client has ended.")
        } catch (e: Exception) {
            safeChannel?.error("client end connection", e.message, "")
        }
    }

    companion object {
        private const val TAG = "InappPurchasePlugin"
        private const val PLAY_STORE_URL = "https://play.google.com/store/account/subscriptions"
        private var productDetailsList: ArrayList<ProductDetails> = arrayListOf()
    }
}