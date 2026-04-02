package dev.kaique.amplitude_experiments_flutter

import android.app.Application
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.amplitude.experiment.Experiment
import com.amplitude.experiment.ExperimentClient
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * Implementation of the Pigeon-generated [AmplitudeExperimentsApi] interface.
 *
 * This class bridges Flutter calls to the native Amplitude Experiments SDK.
 */
class AmplitudeExperimentsApiImpl(
    private val context: Context,
) : AmplitudeExperimentsApi {
    @Volatile
    private var client: ExperimentClient? = null

    private val application: Application
        get() = context.applicationContext as Application

    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler: Handler = Handler(Looper.getMainLooper())

    private fun requireClient(): ExperimentClient =
        client
            ?: throw FlutterError("NOT_INITIALIZED", "Client not initialized. Call initialize() first.", null)

    private fun executeInBackground(
        errorCode: String,
        callback: (Result<Unit>) -> Unit,
        block: () -> Unit,
    ) {
        try {
            executor.execute {
                try {
                    block()
                    mainHandler.post { callback(Result.success(Unit)) }
                } catch (e: FlutterError) {
                    mainHandler.post { callback(Result.failure(e)) }
                } catch (e: Exception) {
                    mainHandler.post {
                        callback(Result.failure(FlutterError(errorCode, e.message, e.stackTraceToString())))
                    }
                }
            }
        } catch (_: RejectedExecutionException) {
            callback(Result.failure(FlutterError("SHUTDOWN", "Plugin has been detached.", null)))
        }
    }

    override fun initialize(
        deploymentKey: String,
        config: ExperimentConfigMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        executeInBackground("INIT_ERROR", callback) {
            if (client != null) return@executeInBackground
            val nativeConfig = ModelConverters.configFromMessage(config)
            client = Experiment.initialize(application, deploymentKey, nativeConfig)
        }
    }

    override fun initializeWithAmplitudeAnalytics(
        deploymentKey: String,
        config: ExperimentConfigMessage,
        callback: (Result<Unit>) -> Unit,
    ) {
        executeInBackground("INIT_ANALYTICS_ERROR", callback) {
            if (client != null) return@executeInBackground
            val nativeConfig = ModelConverters.configFromMessage(config)
            client = Experiment.initializeWithAmplitudeAnalytics(application, deploymentKey, nativeConfig)
        }
    }

    override fun fetch(
        user: ExperimentUserMessage?,
        callback: (Result<Unit>) -> Unit,
    ) {
        executeInBackground("FETCH_ERROR", callback) {
            val experimentClient = requireClient()
            val nativeUser = ModelConverters.userFromMessage(user)
            experimentClient.fetch(nativeUser).get()
        }
    }

    override fun variant(
        key: String,
        fallback: VariantMessage?,
    ): VariantMessage? {
        val experimentClient = requireClient()

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
        val experimentClient = requireClient()
        val variants = experimentClient.all()
        return ModelConverters.variantMapToMessages(variants)
    }

    override fun exposure(key: String) {
        val experimentClient = requireClient()
        experimentClient.exposure(key)
    }

    override fun clear() {
        client?.clear()
    }

    fun shutdown() {
        executor.shutdownNow()
    }
}
