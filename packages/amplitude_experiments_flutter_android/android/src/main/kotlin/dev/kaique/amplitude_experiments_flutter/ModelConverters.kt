package dev.kaique.amplitude_experiments_flutter

import com.amplitude.experiment.ExperimentConfig
import com.amplitude.experiment.ExperimentUser
import com.amplitude.experiment.Variant
import org.json.JSONArray
import org.json.JSONObject

/**
 * Converts between Pigeon message types and native Amplitude SDK types.
 */
object ModelConverters {
    /**
     * Converts a [JSONObject] to a [Map] that can be serialized by Flutter's StandardMessageCodec.
     * Recursively converts nested JSONObject and JSONArray to Map and List.
     */
    private fun jsonObjectToMap(json: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            map[key] = convertJsonValue(json.get(key))
        }
        return map
    }

    /**
     * Converts a [JSONArray] to a [List] that can be serialized by Flutter's StandardMessageCodec.
     */
    private fun jsonArrayToList(array: JSONArray): List<Any?> {
        val list = mutableListOf<Any?>()
        for (i in 0 until array.length()) {
            list.add(convertJsonValue(array.get(i)))
        }
        return list
    }

    /**
     * Converts a JSON value to a type that can be serialized by Flutter's StandardMessageCodec.
     */
    private fun convertJsonValue(value: Any?): Any? =
        when (value) {
            is JSONObject -> jsonObjectToMap(value)
            is JSONArray -> jsonArrayToList(value)
            JSONObject.NULL -> null
            else -> value
        }

    /**
     * Converts a [ServerZoneMessage] to the native Amplitude [com.amplitude.experiment.ServerZone].
     */
    fun serverZoneFromMessage(message: ServerZoneMessage): com.amplitude.experiment.ServerZone =
        when (message) {
            ServerZoneMessage.US -> com.amplitude.experiment.ServerZone.US
            ServerZoneMessage.EU -> com.amplitude.experiment.ServerZone.EU
        }

    /**
     * Converts an [ExperimentConfigMessage] to the native Amplitude [ExperimentConfig].
     */
    fun configFromMessage(message: ExperimentConfigMessage): ExperimentConfig {
        val builder =
            ExperimentConfig
                .builder()
                .debug(message.debug)
                .serverZone(serverZoneFromMessage(message.serverZone))
                .fetchTimeoutMillis(message.fetchTimeoutMillis)
                .retryFetchOnFailure(message.retryFetchOnFailure > 0)
                .automaticExposureTracking(message.automaticExposureTracking)
                .fetchOnStart(message.fetchOnStart)

        message.instanceName?.let { builder.instanceName(it) }

        message.initialVariants?.let { variants ->
            val nativeVariants =
                variants
                    .mapNotNull { (key, variantMessage) ->
                        if (key != null && variantMessage != null) {
                            key to variantFromMessage(variantMessage)
                        } else {
                            null
                        }
                    }.toMap()
            builder.initialVariants(nativeVariants)
        }

        return builder.build()
    }

    /**
     * Converts an [ExperimentUserMessage] to the native Amplitude [ExperimentUser].
     */
    fun userFromMessage(message: ExperimentUserMessage?): ExperimentUser? {
        if (message == null) return null

        val builder = ExperimentUser.builder()

        message.userId?.let { builder.userId(it) }
        message.deviceId?.let { builder.deviceId(it) }
        message.userProperties?.let { props ->
            @Suppress("UNCHECKED_CAST")
            val cleanedProps = props.filterKeys { it != null }.mapKeys { it.key!! }
            builder.userProperties(cleanedProps as Map<String, Any?>)
        }
        message.groups?.let { groups ->
            // groups expects Map<String, Set<String>>
            val groupsMap = mutableMapOf<String, Set<String>>()
            groups.forEach { (key, value) ->
                if (key != null) {
                    when (value) {
                        is List<*> -> groupsMap[key] = value.filterIsInstance<String>().toSet()
                        is String -> groupsMap[key] = setOf(value)
                        else -> {}
                    }
                }
            }
            builder.groups(groupsMap)
        }
        message.groupProperties?.let { groupProps ->
            // groupProperties expects Map<String, Map<String, Map<String, Any?>>>
            @Suppress("UNCHECKED_CAST")
            val convertedProps = mutableMapOf<String, Map<String, Map<String, Any?>>>()
            groupProps.forEach { (groupType, groupNameDict) ->
                if (groupType != null && groupNameDict != null) {
                    val groupNameMap = mutableMapOf<String, Map<String, Any?>>()
                    (groupNameDict as? Map<*, *>)?.forEach { (groupName, propsDict) ->
                        if (groupName is String && propsDict is Map<*, *>) {
                            @Suppress("UNCHECKED_CAST")
                            groupNameMap[groupName] = propsDict as Map<String, Any?>
                        }
                    }
                    convertedProps[groupType] = groupNameMap
                }
            }
            builder.groupProperties(convertedProps)
        }

        return builder.build()
    }

    /**
     * Converts an [ExperimentUser] to an [ExperimentUserMessage].
     */
    @Suppress("UNCHECKED_CAST")
    fun userToMessage(user: ExperimentUser?): ExperimentUserMessage? {
        if (user == null) return null

        // Convert groups from Map<String, Set<String>> to Map<String?, Any?>
        val groupsMap: Map<String?, Any?>? = user.groups?.map { (k, v) -> k to v.toList() }?.toMap()

        // Convert groupProperties from Map<String, Map<String, Map<String, Any?>>> to Map<String?, Map<String?, Any?>?>
        val groupPropsMap: Map<String?, Map<String?, Any?>?>? =
            user.groupProperties
                ?.map { (groupType, groupNameDict) ->
                    groupType to
                        groupNameDict
                            .map { (groupName, props) ->
                                groupName to props
                            }.toMap() as Map<String?, Any?>?
                }?.toMap()

        return ExperimentUserMessage(
            userId = user.userId,
            deviceId = user.deviceId,
            userProperties = user.userProperties as? Map<String?, Any?>,
            groups = groupsMap,
            groupProperties = groupPropsMap,
        )
    }

    /**
     * Converts a [VariantMessage] to the native Amplitude [Variant].
     */
    fun variantFromMessage(message: VariantMessage): Variant =
        Variant(
            message.value,
            message.payload,
            message.expKey,
            message.key,
        )

    /**
     * Converts a native Amplitude [Variant] to a [VariantMessage].
     * The payload is converted from JSONObject to Map to be serializable by Flutter.
     */
    fun variantToMessage(
        variant: Variant,
        key: String,
    ): VariantMessage =
        VariantMessage(
            key = variant.key ?: key,
            value = variant.value,
            payload = convertJsonValue(variant.payload),
            expKey = variant.expKey,
        )

    /**
     * Converts a map of flag keys to [Variant]s to a map of [VariantMessage]s.
     */
    fun variantMapToMessages(variants: Map<String, Variant>): Map<String?, VariantMessage?> =
        variants
            .map { (key, variant) ->
                key to variantToMessage(variant, key)
            }.toMap()
}
