import 'server_zone.dart';
import 'variant.dart';

/// Configuration for the Amplitude Experiments client
class ExperimentConfig {
  const ExperimentConfig({
    this.debug = false,
    this.instanceName,
    this.serverZone = ServerZone.us,
    this.fetchTimeoutMillis = 10000,
    this.retryFetchOnFailure = 1,
    this.automaticExposureTracking = true,
    this.fetchOnStart = false,
    this.initialVariants,
  });

  /// Enables debug logging
  final bool debug;

  /// Instance name for multiple clients
  final String? instanceName;

  /// Server zone (US or EU)
  final ServerZone serverZone;

  /// Fetch timeout in milliseconds
  final int fetchTimeoutMillis;

  /// Number of retry attempts on failure
  final int retryFetchOnFailure;

  /// Automatic exposure tracking
  final bool automaticExposureTracking;

  /// Automatic fetch on initialization
  final bool fetchOnStart;

  /// Pre-loaded initial variants
  final Map<String, Variant>? initialVariants;

  /// Serializes to JSON
  Map<String, dynamic> toJson() => {
        'debug': debug,
        'instanceName': instanceName,
        'serverZone': serverZone.name,
        'fetchTimeoutMillis': fetchTimeoutMillis,
        'retryFetchOnFailure': retryFetchOnFailure,
        'automaticExposureTracking': automaticExposureTracking,
        'fetchOnStart': fetchOnStart,
        'initialVariants': initialVariants?.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      };

  @override
  String toString() => 'ExperimentConfig('
      'debug: $debug, '
      'instanceName: $instanceName, '
      'serverZone: $serverZone, '
      'fetchTimeoutMillis: $fetchTimeoutMillis)';
}
