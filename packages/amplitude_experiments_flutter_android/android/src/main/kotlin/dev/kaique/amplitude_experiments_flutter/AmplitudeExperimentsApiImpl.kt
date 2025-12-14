package dev.kaique.amplitude_experiments_flutter

import android.app.Application
import android.content.Context
import com.amplitude.experiment.Experiment
import com.amplitude.experiment.ExperimentClient

/**
 * Implementation of the Pigeon-generated [AmplitudeExperimentsApi] interface.
 *
 * This class bridges Flutter calls to the native Amplitude Experiments SDK.
 */
class AmplitudeExperimentsApiImpl(
    private val context: Context,
) : AmplitudeExperimentsApi {
    private var client: ExperimentClient? = null

    private val application: Application
        get() = context.applicationContext as Application

    override fun initialize(
        deploymentKey: String,
        config: ExperimentConfigMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        try {
            val nativeConfig = ModelConverters.configFromMessage(config)
            client = Experiment.initialize(application, deploymentKey, nativeConfig)
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("INIT_ERROR", e.message, e.stackTraceToString())))
        }
    }

    override fun initializeWithAmplitudeAnalytics(
        deploymentKey: String,
        config: ExperimentConfigMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        try {
            val nativeConfig = ModelConverters.configFromMessage(config)
            client = Experiment.initializeWithAmplitudeAnalytics(application, deploymentKey, nativeConfig)
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("INIT_ANALYTICS_ERROR", e.message, e.stackTraceToString())))
        }
    }

    override fun fetch(
        user: ExperimentUserMessage?,
        callback: (Result<Unit>) -> Unit,
    ) {
        val experimentClient = client
        if (experimentClient == null) {
            callback(Result.failure(FlutterError("NOT_INITIALIZED", "Client not initialized. Call initialize() first.", null)))
            return
        }

        try {
            val nativeUser = ModelConverters.userFromMessage(user)
            experimentClient.fetch(nativeUser).get()
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("FETCH_ERROR", e.message, e.stackTraceToString())))
        }
    }

    override fun variant(
        key: String,
        fallback: VariantMessage?,
    ): VariantMessage? {
        val experimentClient =
            client
                ?: throw FlutterError("NOT_INITIALIZED", "Client not initialized. Call initialize() first.", null)

        val nativeFallback = fallback?.let { ModelConverters.variantFromMessage(it) }
        val variant =
            if (nativeFallback != null) {
                experimentClient.variant(key, nativeFallback)
            } else {
                experimentClient.variant(key)
            }

        return if (variant.value != null || variant.payload != null || variant.expKey != null || variant.key != null) {
            ModelConverters.variantToMessage(variant, key)
        } else {
            null
        }
    }

    override fun all(): Map<String?, VariantMessage?> {
        val experimentClient =
            client
                ?: throw FlutterError("NOT_INITIALIZED", "Client not initialized. Call initialize() first.", null)

        val variants = experimentClient.all()
        return ModelConverters.variantMapToMessages(variants)
    }

    override fun exposure(key: String) {
        val experimentClient =
            client
                ?: throw FlutterError("NOT_INITIALIZED", "Client not initialized. Call initialize() first.", null)

        experimentClient.exposure(key)
    }

    override fun clear() {
        client?.clear()
    }
}
