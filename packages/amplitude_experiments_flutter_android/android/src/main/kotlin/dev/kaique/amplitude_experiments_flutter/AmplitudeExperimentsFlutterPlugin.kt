package dev.kaique.amplitude_experiments_flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Flutter plugin for Amplitude Experiments on Android.
 *
 * This plugin registers the Pigeon-generated API handler to enable
 * communication between Flutter and the native Amplitude Experiments SDK.
 */
class AmplitudeExperimentsFlutterPlugin : FlutterPlugin {
    private var apiImpl: AmplitudeExperimentsApiImpl? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        apiImpl = AmplitudeExperimentsApiImpl(context)
        AmplitudeExperimentsApi.setUp(flutterPluginBinding.binaryMessenger, apiImpl)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AmplitudeExperimentsApi.setUp(binding.binaryMessenger, null)
        apiImpl = null
    }
}
