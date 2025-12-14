import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';

/// Main entry point for the Amplitude Experiments Flutter SDK.
///
/// This class provides a static API for interacting with Amplitude Experiments,
/// including initialization, fetching variants, and tracking exposures.
///
/// Example usage:
/// ```dart
/// // Initialize the client
/// await AmplitudeExperiments.initialize(
///   'YOUR-DEPLOYMENT-KEY',
///   config: const ExperimentConfig(debug: true),
/// );
///
/// // Fetch variants for a user
/// await AmplitudeExperiments.fetch(
///   ExperimentUser(userId: 'user-123'),
/// );
///
/// // Get a variant
/// final variant = await AmplitudeExperiments.variant('feature-flag');
/// if (variant?.value == 'on') {
///   // Show new feature
/// }
/// ```
class AmplitudeExperiments {
  AmplitudeExperiments._();

  static AmplitudeExperimentsFlutterPlatform get _platform =>
      AmplitudeExperimentsFlutterPlatform.instance;

  /// Initialize the Amplitude Experiments client.
  ///
  /// [deploymentKey] is the deployment key from Amplitude Experiments.
  /// [config] contains optional configuration options for the client.
  ///
  /// This method should be called before any other methods.
  static Future<void> initialize(
    String deploymentKey, {
    ExperimentConfig? config,
  }) {
    return _platform.initialize(
      deploymentKey,
      config ?? const ExperimentConfig(),
    );
  }

  /// Initialize the client with Amplitude Analytics integration.
  ///
  /// This enables automatic user identity and exposure tracking through Analytics.
  /// [deploymentKey] is the deployment key from Amplitude Experiments.
  /// [config] contains optional configuration options for the client.
  static Future<void> initializeWithAmplitudeAnalytics(
    String deploymentKey, {
    ExperimentConfig? config,
  }) {
    return _platform.initializeWithAmplitudeAnalytics(
      deploymentKey,
      config ?? const ExperimentConfig(),
    );
  }

  /// Fetch variants from the server for the specified user.
  ///
  /// [user] contains the user context for targeting. Can be null for anonymous users.
  /// The fetched variants are cached locally and can be accessed via [variant] or [all].
  static Future<void> fetch([ExperimentUser? user]) {
    return _platform.fetch(user);
  }

  /// Get the variant for the specified flag key.
  ///
  /// [key] is the flag key to look up.
  /// [fallback] is returned if the variant is not found.
  /// Returns the variant for the key, or the fallback if not found.
  static Future<Variant?> variant(String key, [Variant? fallback]) {
    return _platform.variant(key, fallback);
  }

  /// Get all variants for the current user.
  ///
  /// Returns a map of flag keys to their variants.
  static Future<Map<String, Variant>> all() {
    return _platform.all();
  }

  /// Track an exposure event for a flag.
  ///
  /// [key] is the flag key to track exposure for.
  /// Use this for manual exposure tracking when [ExperimentConfig.automaticExposureTracking]
  /// is set to false.
  static Future<void> exposure(String key) {
    return _platform.exposure(key);
  }

  /// Clear all variants and user data from the local cache.
  ///
  /// This is useful when the user logs out or you need to reset the experiment state.
  static Future<void> clear() {
    return _platform.clear();
  }
}
