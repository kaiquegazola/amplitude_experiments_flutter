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
    private let serialQueue = DispatchQueue(label: "dev.kaique.amplitude_experiments_flutter")

    private func requireClient() throws -> ExperimentClient {
        guard let client = client else {
            throw PigeonError(
                code: "NOT_INITIALIZED",
                message: "Client not initialized. Call initialize() first.",
                details: nil
            )
        }
        return client
    }

    private func performInitialize(
        errorCode: String,
        completion: @escaping (Result<Void, Error>) -> Void,
        block: @escaping () throws -> ExperimentClient
    ) {
        serialQueue.async {
            do {
                let initializedClient = try block()
                self.client = initializedClient
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(PigeonError(
                        code: errorCode,
                        message: error.localizedDescription,
                        details: nil
                    )))
                }
            }
        }
    }

    func initialize(
        deploymentKey: String,
        config: ExperimentConfigMessage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        performInitialize(errorCode: "INIT_ERROR", completion: completion) {
            let configBuilder = ModelConverters.configFromMessage(config)
            return Experiment.initialize(apiKey: deploymentKey, config: configBuilder.build())
        }
    }

    func initializeWithAmplitudeAnalytics(
        deploymentKey: String,
        config: ExperimentConfigMessage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        performInitialize(errorCode: "INIT_ANALYTICS_ERROR", completion: completion) {
            let configBuilder = ModelConverters.configFromMessage(config)
            return Experiment.initializeWithAmplitudeAnalytics(
                apiKey: deploymentKey,
                config: configBuilder.build()
            )
        }
    }

    func fetch(
        user: ExperimentUserMessage?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        serialQueue.async {
            do {
                let client = try self.requireClient()
                let nativeUser = ModelConverters.userFromMessage(user)
                client.fetch(user: nativeUser) { _, error in
                    DispatchQueue.main.async {
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
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    func variant(key: String, fallback: VariantMessage?) throws -> VariantMessage? {
        let client = try requireClient()

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
        let client = try requireClient()
        let variants = client.all()
        return ModelConverters.variantMapToMessages(variants)
    }

    func exposure(key: String) throws {
        let client = try requireClient()
        client.exposure(key: key)
    }

    func clear() throws {
        client?.clear()
    }
}
