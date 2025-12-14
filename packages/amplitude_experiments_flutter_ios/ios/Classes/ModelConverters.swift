import AmplitudeExperiment
import Foundation

/// Converts between Pigeon message types and native Amplitude SDK types.
enum ModelConverters {
    /// Converts a ServerZoneMessage to the native Amplitude ServerZone.
    static func serverZoneFromMessage(_ message: ServerZoneMessage) -> ServerZone {
        switch message {
        case .us:
            return .US
        case .eu:
            return .EU
        }
    }

    /// Converts an ExperimentConfigMessage to the native Amplitude ExperimentConfig.
    static func configFromMessage(_ message: ExperimentConfigMessage) -> ExperimentConfigBuilder {
        let builder = ExperimentConfigBuilder()
            .debug(message.debug)
            .serverZone(serverZoneFromMessage(message.serverZone))
            .fetchTimeoutMillis(Int(message.fetchTimeoutMillis))
            .fetchRetryOnFailure(message.retryFetchOnFailure > 0)
            .automaticExposureTracking(message.automaticExposureTracking)
            .fetchOnStart(message.fetchOnStart)

        if let instanceName = message.instanceName {
            builder.instanceName(instanceName)
        }

        if let initialVariants = message.initialVariants {
            var nativeVariants: [String: Variant] = [:]
            for (key, variantMessage) in initialVariants {
                if let key = key, let variantMessage = variantMessage {
                    nativeVariants[key] = variantFromMessage(variantMessage)
                }
            }
            builder.initialVariants(nativeVariants)
        }

        return builder
    }

    /// Converts an ExperimentUserMessage to the native Amplitude ExperimentUser.
    static func userFromMessage(_ message: ExperimentUserMessage?) -> ExperimentUser? {
        guard let message = message else { return nil }

        let builder = ExperimentUserBuilder()

        if let userId = message.userId {
            builder.userId(userId)
        }
        if let deviceId = message.deviceId {
            builder.deviceId(deviceId)
        }
        if let userProperties = message.userProperties {
            var props: [String: Any] = [:]
            for (key, value) in userProperties {
                if let key = key, let value = value {
                    props[key] = value
                }
            }
            builder.userProperties(props)
        }
        if let groups = message.groups {
            var groupsDict: [String: [String]] = [:]
            for (key, value) in groups {
                if let key = key, let value = value as? [String] {
                    groupsDict[key] = value
                } else if let key = key, let singleValue = value as? String {
                    groupsDict[key] = [singleValue]
                }
            }
            builder.groups(groupsDict)
        }
        if let groupProperties = message.groupProperties {
            // groupProperties expects [String: [String: [String: Any]]]
            // groupType -> groupName -> propertyKey -> propertyValue
            var groupPropsDict: [String: [String: [String: Any]]] = [:]
            for (groupType, groupNameDict) in groupProperties {
                if let groupType = groupType, let groupNameDict = groupNameDict as? [String: Any] {
                    var groupNamePropsDict: [String: [String: Any]] = [:]
                    for (groupName, propsDict) in groupNameDict {
                        if let propsDict = propsDict as? [String: Any] {
                            groupNamePropsDict[groupName] = propsDict
                        }
                    }
                    groupPropsDict[groupType] = groupNamePropsDict
                }
            }
            builder.groupProperties(groupPropsDict)
        }

        return builder.build()
    }

    /// Converts a VariantMessage to the native Amplitude Variant.
    static func variantFromMessage(_ message: VariantMessage) -> Variant {
        return Variant(
            message.value,
            payload: message.payload,
            expKey: message.expKey,
            key: message.key
        )
    }

    /// Converts a native Amplitude Variant to a VariantMessage.
    static func variantToMessage(_ variant: Variant, key: String) -> VariantMessage {
        return VariantMessage(
            key: variant.key ?? key,
            value: variant.value,
            payload: variant.payload,
            expKey: variant.expKey
        )
    }

    /// Converts a map of flag keys to Variants to a map of VariantMessages.
    static func variantMapToMessages(_ variants: [String: Variant]) -> [String?: VariantMessage?] {
        var result: [String?: VariantMessage?] = [:]
        for (key, variant) in variants {
            result[key] = variantToMessage(variant, key: key)
        }
        return result
    }
}
