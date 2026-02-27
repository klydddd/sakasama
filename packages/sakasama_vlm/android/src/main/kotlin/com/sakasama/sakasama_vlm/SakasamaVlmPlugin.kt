package com.sakasama.sakasama_vlm

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** SakasamaVlmPlugin */
class SakasamaVlmPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    
    // Create a CoroutineScope bound to the plugin's lifecycle 
    // using the Default dispatcher (optimized for CPU-intensive work)
    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    /**
     * Declares the JNI function implemented in got_ocr_bridge.cpp
     */
    private external fun scanImageNative(
        imagePath: String, 
        baseModelPath: String, 
        visionModelPath: String, 
        prompt: String
    ): String

    companion object {
        init {
            // Load the C++ shared library compiled via CMakeLists.txt
            System.loadLibrary("sakasama_vlm")
        }
    }

    private fun copyAsset(assetKey: String, targetPath: String) {
        val assetManager = context?.assets ?: throw Exception("Context not found")
        
        // Flutter assets are usually nested under 'flutter_assets/' in the APK
        // The assetKey passed from Dart already includes the path but might need prefix adjustments
        // depending on how the plugin is registered. Usually it's the full path from pubspec.
        
        val inputStream: InputStream = assetManager.open("flutter_assets/$assetKey")
        val outFile = File(targetPath)
        outFile.parentFile?.mkdirs()
        
        val outputStream = FileOutputStream(outFile)
        val buffer = ByteArray(1024 * 64) // 64KB buffer
        var read: Int
        while (inputStream.read(buffer).also { read = it } != -1) {
            outputStream.write(buffer, 0, read)
        }
        outputStream.flush()
        outputStream.close()
        inputStream.close()
    }

    private var context: android.content.Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sakasama_vlm")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "scanImageWithGotOcr") {
            val imagePath = call.argument<String>("imagePath")
            val baseModelPath = call.argument<String>("baseModelPath")
            val visionModelPath = call.argument<String>("visionModelPath")
            val prompt = call.argument<String>("prompt")

            if (imagePath == null || baseModelPath == null || visionModelPath == null || prompt == null) {
                result.error("INVALID_ARGS", "Missing required arguments for scanImageWithGotOcr", null)
                return
            }

            // Execute the heavy C++ VLM inference on a background thread
            pluginScope.launch {
                try {
                    val jsonResponse = scanImageNative(imagePath, baseModelPath, visionModelPath, prompt)
                    
                    // Switch back to Main thread to return the result to Flutter
                    withContext(Dispatchers.Main) {
                        result.success(jsonResponse)
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        result.error("NATIVE_INFERENCE_ERROR", e.localizedMessage, e.stackTraceToString())
                    }
                }
            }
        } else if (call.method == "copyAssetToPath") {
            val assetKey = call.argument<String>("assetKey")
            val targetPath = call.argument<String>("targetPath")

            if (assetKey == null || targetPath == null) {
                result.error("INVALID_ARGS", "Missing assetKey or targetPath", null)
                return
            }

            pluginScope.launch {
                try {
                    copyAsset(assetKey, targetPath)
                    withContext(Dispatchers.Main) {
                        result.success(true)
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        result.error("COPY_ERROR", e.localizedMessage, null)
                    }
                }
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
