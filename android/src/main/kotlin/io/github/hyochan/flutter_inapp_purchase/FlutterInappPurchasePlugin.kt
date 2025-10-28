package io.github.hyochan.flutter_inapp_purchase

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import android.content.Context
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.content.pm.PackageManager.NameNotFoundException

/** FlutterInappPurchasePlugin  */
class FlutterInappPurchasePlugin : FlutterPlugin, ActivityAware {
    private var androidInappPurchasePlugin: AndroidInappPurchasePlugin? = null
    private var amazonInappPurchasePlugin: AmazonInappPurchasePlugin? = null
    private var channel: MethodChannel? = null
    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        onAttached(binding.applicationContext, binding.binaryMessenger)
    }

    private fun onAttached(context: Context, messenger: BinaryMessenger) {
        isAndroid = isPackageInstalled(context, "com.android.vending")
        isAmazon = isPackageInstalled(context, "com.amazon.venezia")

        // In the case of an amazon device which has been side loaded with the Google Play store,
        // we should use the store the app was installed from.
        if (isAmazon && isAndroid) {
            if (isAppInstalledFrom(context, "amazon")) {
                isAndroid = false
            } else {
                isAmazon = false
            }
        }

        // If neither Play Store nor Amazon is detected, default to Android (for Horizon and other stores)
        // This allows openiap to handle different billing implementations via flavors
        if (!isAndroid && !isAmazon) {
            android.util.Log.i("FlutterInappPurchase", "No Play Store or Amazon detected - defaulting to Android plugin (supports Horizon and other stores)")
            isAndroid = true
        }

        channel = MethodChannel(messenger, "flutter_inapp")
        if (isAndroid) {
            android.util.Log.i("FlutterInappPurchase", "Initializing Android IAP plugin")
            val plugin = AndroidInappPurchasePlugin()
            plugin.setContext(context)
            plugin.setChannel(channel)
            androidInappPurchasePlugin = plugin
            channel!!.setMethodCallHandler(plugin)
        } else if (isAmazon) {
            android.util.Log.i("FlutterInappPurchase", "Initializing Amazon IAP plugin")
            amazonInappPurchasePlugin = AmazonInappPurchasePlugin()
            amazonInappPurchasePlugin!!.setContext(context)
            amazonInappPurchasePlugin!!.setChannel(channel)
            channel!!.setMethodCallHandler(amazonInappPurchasePlugin)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
        channel = null
        if (isAndroid) {
            androidInappPurchasePlugin?.setChannel(null)
        } else if (isAmazon) {
            amazonInappPurchasePlugin!!.setChannel(null)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        if (isAndroid) {
            androidInappPurchasePlugin?.setActivity(binding.activity)
        } else if (isAmazon) {
            amazonInappPurchasePlugin!!.setActivity(binding.activity)
        }
    }

    override fun onDetachedFromActivity() {
        if (isAndroid) {
            androidInappPurchasePlugin?.setActivity(null)
            androidInappPurchasePlugin?.onDetachedFromActivity()
        } else if (isAmazon) {
            amazonInappPurchasePlugin!!.setActivity(null)
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    private fun setAndroidInappPurchasePlugin(androidInappPurchasePlugin: AndroidInappPurchasePlugin) {
        this.androidInappPurchasePlugin = androidInappPurchasePlugin
    }

    private fun setAmazonInappPurchasePlugin(amazonInappPurchasePlugin: AmazonInappPurchasePlugin) {
        this.amazonInappPurchasePlugin = amazonInappPurchasePlugin
    }

    companion object {
        private var isAndroid = false
        private var isAmazon = false

        fun getStore(): String {
           return if (!isAndroid && !isAmazon) "none" else if (isAndroid) "play_store" else "amazon"
        }

        private fun isPackageInstalled(ctx: Context, packageName: String): Boolean {
            return try {
                ctx.packageManager.getPackageInfo(packageName, 0)
                true
            } catch (e: NameNotFoundException) {
                false
            }
        }

        fun isAppInstalledFrom(ctx: Context, installer: String?): Boolean {
            val installerPackageName = ctx.packageManager.getInstallerPackageName(ctx.packageName)
            return installer != null && installerPackageName != null && installerPackageName.contains(
                installer
            )
        }
    }
}
