import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/messages.g.dart',
    kotlinOut:
        '../amplitude_experiments_flutter_android/android/src/main/kotlin/dev/kaique/amplitude_experiments_flutter/Messages.g.kt',
    swiftOut:
        '../amplitude_experiments_flutter_ios/ios/Classes/Messages.g.swift',
    kotlinOptions: KotlinOptions(
      package: 'dev.kaique.amplitude_experiments_flutter',
    ),
    swiftOptions: SwiftOptions(),
    dartPackageName: 'amplitude_experiments_flutter_platform_interface',
  ),
)

/// Server zone for Amplitude data center region
enum ServerZoneMessage {
  us,
  eu,
}

/// Configuration message for the Amplitude Experiments client
class ExperimentConfigMessage {
  ExperimentConfigMessage({
    required this.debug,
    required this.serverZone,
    required this.fetchTimeoutMillis,
    required this.retryFetchOnFailure,
    required this.automaticExposureTracking,
    required this.fetchOnStart,
    this.instanceName,
    this.initialVariants,
  });

  final bool debug;
  final String? instanceName;
  final ServerZoneMessage serverZone;
  final int fetchTimeoutMillis;
  final int retryFetchOnFailure;
  final bool automaticExposureTracking;
  final bool fetchOnStart;
  final Map<String?, VariantMessage?>? initialVariants;
}

/// User context message for experiment targeting
class ExperimentUserMessage {
  ExperimentUserMessage({
    this.userId,
    this.deviceId,
    this.userProperties,
    this.groups,
    this.groupProperties,
  });

  final String? userId;
  final String? deviceId;
  final Map<String?, Object?>? userProperties;
  final Map<String?, Object?>? groups;
  final Map<String?, Map<String?, Object?>?>? groupProperties;
}

/// Variant message representing an experiment variant
class VariantMessage {
  VariantMessage({
    required this.key,
    this.value,
    this.payload,
    this.expKey,
  });

  final String key;
  final String? value;
  final Object? payload;
  final String? expKey;
}

/// Host API for Amplitude Experiments platform communication
@HostApi()
abstract class AmplitudeExperimentsApi {
  /// Initialize the Amplitude Experiments client
  @async
  void initialize(String deploymentKey, ExperimentConfigMessage config);

  /// Initialize with Amplitude Analytics integration
  @async
  void initializeWithAmplitudeAnalytics(
    String deploymentKey,
    ExperimentConfigMessage config,
  );

  /// Fetch variants for a user
  @async
  void fetch(ExperimentUserMessage? user);

  /// Get a specific variant by key
  VariantMessage? variant(String key, VariantMessage? fallback);

  /// Get all variants
  Map<String?, VariantMessage?> all();

  /// Track exposure for a variant
  void exposure(String key);

  /// Clear all variants
  void clear();
}
