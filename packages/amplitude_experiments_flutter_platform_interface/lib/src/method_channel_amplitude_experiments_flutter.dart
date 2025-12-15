import 'package:flutter/foundation.dart';

import 'amplitude_experiments_flutter_platform.dart';
import 'converters/pigeon_converters.dart';
import 'generated/messages.g.dart';
import 'models/experiment_config.dart';
import 'models/experiment_user.dart';
import 'models/variant.dart';

/// An implementation of [AmplitudeExperimentsFlutterPlatform] that uses Pigeon.
class MethodChannelAmplitudeExperimentsFlutter
    extends AmplitudeExperimentsFlutterPlatform {
  /// Creates a new instance with an optional API for testing.
  MethodChannelAmplitudeExperimentsFlutter({AmplitudeExperimentsApi? api})
      : _api = api ?? AmplitudeExperimentsApi();

  /// The Pigeon API used to interact with the native platform.
  @visibleForTesting
  AmplitudeExperimentsApi get api => _api;
  final AmplitudeExperimentsApi _api;

  @override
  Future<void> initialize(String deploymentKey, ExperimentConfig config) async {
    final configMessage = PigeonConverters.configToMessage(config);
    await api.initialize(deploymentKey, configMessage);
  }

  @override
  Future<void> initializeWithAmplitudeAnalytics(
    String deploymentKey,
    ExperimentConfig config,
  ) async {
    final configMessage = PigeonConverters.configToMessage(config);
    await api.initializeWithAmplitudeAnalytics(deploymentKey, configMessage);
  }

  @override
  Future<void> fetch(ExperimentUser? user) async {
    final userMessage = PigeonConverters.userToMessage(user);
    await api.fetch(userMessage);
  }

  @override
  Future<Variant?> variant(String key, Variant? fallback) async {
    final fallbackMessage =
        fallback != null ? PigeonConverters.variantToMessage(fallback) : null;
    final result = await api.variant(key, fallbackMessage);
    return result != null ? PigeonConverters.variantFromMessage(result) : null;
  }

  @override
  Future<Map<String, Variant>> all() async {
    final result = await api.all();
    return PigeonConverters.variantMapFromMessages(result);
  }

  @override
  Future<void> exposure(String key) async {
    await api.exposure(key);
  }

  @override
  Future<void> clear() async {
    await api.clear();
  }
}
