import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_amplitude_experiments_flutter.dart';
import 'models/experiment_config.dart';
import 'models/experiment_user.dart';
import 'models/variant.dart';

/// The interface that implementations of amplitude_experiments_flutter must implement.
///
/// Platform implementations should extend this class rather than implement it as
/// `AmplitudeExperimentsFlutterPlatform` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass will get the
/// default implementation, while platform implementations that `implements` this interface
/// will be broken by newly added methods.
abstract class AmplitudeExperimentsFlutterPlatform extends PlatformInterface {
  /// Constructs a AmplitudeExperimentsFlutterPlatform.
  AmplitudeExperimentsFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static AmplitudeExperimentsFlutterPlatform _instance =
      MethodChannelAmplitudeExperimentsFlutter();

  /// The default instance of [AmplitudeExperimentsFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelAmplitudeExperimentsFlutter].
  static AmplitudeExperimentsFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AmplitudeExperimentsFlutterPlatform]
  /// when they register themselves.
  static set instance(AmplitudeExperimentsFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the Amplitude Experiments client with a deployment key and configuration.
  ///
  /// [deploymentKey] is the deployment key from Amplitude Experiments.
  /// [config] contains configuration options for the client.
  Future<void> initialize(String deploymentKey, ExperimentConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Initialize the client with Amplitude Analytics integration.
  ///
  /// This enables automatic user identity and exposure tracking through Analytics.
  /// [deploymentKey] is the deployment key from Amplitude Experiments.
  /// [config] contains configuration options for the client.
  Future<void> initializeWithAmplitudeAnalytics(
    String deploymentKey,
    ExperimentConfig config,
  ) {
    throw UnimplementedError(
      'initializeWithAmplitudeAnalytics() has not been implemented.',
    );
  }

  /// Fetch variants for a user.
  ///
  /// [user] contains the user context for targeting. Can be null for anonymous users.
  Future<void> fetch(ExperimentUser? user) {
    throw UnimplementedError('fetch() has not been implemented.');
  }

  /// Get a specific variant by flag key.
  ///
  /// [key] is the flag key to look up.
  /// [fallback] is returned if the variant is not found.
  /// Returns the variant for the key, or the fallback if not found.
  Future<Variant?> variant(String key, Variant? fallback) {
    throw UnimplementedError('variant() has not been implemented.');
  }

  /// Get all variants for the current user.
  ///
  /// Returns a map of flag keys to their variants.
  Future<Map<String, Variant>> all() {
    throw UnimplementedError('all() has not been implemented.');
  }

  /// Track an exposure event for a flag.
  ///
  /// [key] is the flag key to track exposure for.
  Future<void> exposure(String key) {
    throw UnimplementedError('exposure() has not been implemented.');
  }

  /// Clear all variants and user data.
  Future<void> clear() {
    throw UnimplementedError('clear() has not been implemented.');
  }
}
