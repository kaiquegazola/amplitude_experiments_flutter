import '../generated/messages.g.dart';
import '../models/experiment_config.dart';
import '../models/experiment_user.dart';
import '../models/server_zone.dart';
import '../models/variant.dart';

/// Converters for transforming between Pigeon messages and domain models
class PigeonConverters {
  PigeonConverters._();

  // ============== Variant Conversions ==============

  /// Converts a [VariantMessage] to a [Variant] domain model
  static Variant variantFromMessage(VariantMessage message) {
    return Variant(
      key: message.key,
      value: message.value,
      payload: message.payload,
      expKey: message.expKey,
    );
  }

  /// Converts a [Variant] domain model to a [VariantMessage]
  static VariantMessage variantToMessage(Variant variant) {
    return VariantMessage(
      key: variant.key,
      value: variant.value,
      payload: variant.payload,
      expKey: variant.expKey,
    );
  }

  // ============== ExperimentUser Conversions ==============

  /// Converts an [ExperimentUser] to an [ExperimentUserMessage]
  /// Returns null if the input is null
  static ExperimentUserMessage? userToMessage(ExperimentUser? user) {
    if (user == null) return null;
    return ExperimentUserMessage(
      userId: user.userId,
      deviceId: user.deviceId,
      userProperties: user.userProperties,
      groups: user.groups,
      groupProperties: user.groupProperties,
    );
  }

  /// Converts an [ExperimentUserMessage] to an [ExperimentUser]
  /// Returns null if the input is null
  static ExperimentUser? userFromMessage(ExperimentUserMessage? message) {
    if (message == null) return null;
    return ExperimentUser(
      userId: message.userId,
      deviceId: message.deviceId,
      userProperties: message.userProperties?.cast<String, dynamic>(),
      groups: message.groups?.cast<String, dynamic>(),
      groupProperties: message.groupProperties?.map(
        (key, value) => MapEntry(
          key ?? '',
          value?.cast<String, dynamic>() ?? {},
        ),
      ),
    );
  }

  // ============== ServerZone Conversions ==============

  /// Converts a [ServerZone] to a [ServerZoneMessage]
  static ServerZoneMessage serverZoneToMessage(ServerZone zone) {
    return switch (zone) {
      ServerZone.us => ServerZoneMessage.us,
      ServerZone.eu => ServerZoneMessage.eu,
    };
  }

  /// Converts a [ServerZoneMessage] to a [ServerZone]
  static ServerZone serverZoneFromMessage(ServerZoneMessage message) {
    return switch (message) {
      ServerZoneMessage.us => ServerZone.us,
      ServerZoneMessage.eu => ServerZone.eu,
    };
  }

  // ============== ExperimentConfig Conversions ==============

  /// Converts an [ExperimentConfig] to an [ExperimentConfigMessage]
  static ExperimentConfigMessage configToMessage(ExperimentConfig config) {
    return ExperimentConfigMessage(
      debug: config.debug,
      instanceName: config.instanceName,
      serverZone: serverZoneToMessage(config.serverZone),
      fetchTimeoutMillis: config.fetchTimeoutMillis,
      retryFetchOnFailure: config.retryFetchOnFailure,
      automaticExposureTracking: config.automaticExposureTracking,
      fetchOnStart: config.fetchOnStart,
      initialVariants: config.initialVariants?.map(
        (key, variant) => MapEntry(key, variantToMessage(variant)),
      ),
    );
  }

  // ============== Map Conversions ==============

  /// Converts a map of [VariantMessage] to a map of [Variant]
  /// Throws [ArgumentError] if any message is null
  static Map<String, Variant> variantMapFromMessages(
    Map<String?, VariantMessage?> messages,
  ) {
    return messages.map((key, message) {
      if (message == null) {
        throw ArgumentError('Variant message cannot be null for key: $key');
      }
      return MapEntry(key ?? '', variantFromMessage(message));
    });
  }

  /// Converts a map of [Variant] to a map of [VariantMessage]
  static Map<String, VariantMessage> variantMapToMessages(
    Map<String, Variant> variants,
  ) {
    return variants.map(
      (key, variant) => MapEntry(key, variantToMessage(variant)),
    );
  }
}
