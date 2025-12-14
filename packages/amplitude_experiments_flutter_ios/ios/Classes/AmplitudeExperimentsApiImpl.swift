import AmplitudeExperiment
import Foundation

/// Implementation of the Pigeon-generated AmplitudeExperimentsApi protocol.
///
/// This class bridges Flutter calls to the native Amplitude Experiments SDK.
///
/// Cache behavior:
/// - Variants are automatically persisted to UserDefaults
/// - Cache survives app restarts
/// - fetch() merges new variants with existing cache
/// - clear() removes all cached variants
class AmplitudeExperimentsApiImpl: AmplitudeExperimentsApi {
    private var client: ExperimentClient?

    func initialize(
        deploymentKey: String,
        config: ExperimentConfigMessage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            let configBuilder = ModelConverters.configFromMessage(config)
            client = Experiment.initialize(apiKey: deploymentKey, config: configBuilder.build())
            completion(.success(()))
        } catch {
            completion(.failure(PigeonError(
                code: "INIT_ERROR",
                message: error.localizedDescription,
                details: nil
            )))
        }
    }

    func initializeWithAmplitudeAnalytics(
        deploymentKey: String,
        config: ExperimentConfigMessage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            let configBuilder = ModelConverters.configFromMessage(config)
            client = Experiment.initializeWithAmplitudeAnalytics(
                apiKey: deploymentKey,
                config: configBuilder.build()
            )
            completion(.success(()))
        } catch {
            completion(.failure(PigeonError(
                code: "INIT_ANALYTICS_ERROR",
                message: error.localizedDescription,
                details: nil
            )))
        }
    }

    func fetch(
        user: ExperimentUserMessage?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let client = client else {
            completion(.failure(PigeonError(
                code: "NOT_INITIALIZED",
                message: "Client not initialized. Call initialize() first.",
                details: nil
            )))
            return
        }

        let nativeUser = ModelConverters.userFromMessage(user)
        client.fetch(user: nativeUser) { _, error in
            if let error = error {
                completion(.failure(PigeonError(
                    code: "FETCH_ERROR",
                    message: error.localizedDescription,
                    details: nil
                )))
            } else {
                completion(.success(()))
            }
        }
    }

    func variant(key: String, fallback: VariantMessage?) throws -> VariantMessage? {
        guard let client = client else {
            throw PigeonError(
                code: "NOT_INITIALIZED",
                message: "Client not initialized. Call initialize() first.",
                details: nil
            )
        }

        let nativeFallback = fallback.map { ModelConverters.variantFromMessage($0) }
        let variant: Variant
        if let nativeFallback = nativeFallback {
            variant = client.variant(key, fallback: nativeFallback)
        } else {
            variant = client.variant(key)
        }

        // Return nil if the variant has no meaningful data
        if variant.value == nil && variant.payload == nil && variant.expKey == nil && variant.key == nil {
            return nil
        }

        return ModelConverters.variantToMessage(variant, key: key)
    }

    func all() throws -> [String?: VariantMessage?] {
        guard let client = client else {
            throw PigeonError(
                code: "NOT_INITIALIZED",
                message: "Client not initialized. Call initialize() first.",
                details: nil
            )
        }

        let variants = client.all()
        return ModelConverters.variantMapToMessages(variants)
    }

    func exposure(key: String) throws {
        guard let client = client else {
            throw PigeonError(
                code: "NOT_INITIALIZED",
                message: "Client not initialized. Call initialize() first.",
                details: nil
            )
        }

        client.exposure(key: key)
    }

    func clear() throws {
        client?.clear()
    }
}
