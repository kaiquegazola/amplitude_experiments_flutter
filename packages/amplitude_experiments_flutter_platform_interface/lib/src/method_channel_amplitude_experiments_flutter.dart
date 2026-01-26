import 'dart:async';

import 'package:flutter/foundation.dart';

import 'amplitude_experiments_flutter_platform.dart';
import 'converters/pigeon_converters.dart';
import 'generated/messages.g.dart';
import 'models/experiment_config.dart';
import 'models/experiment_user.dart';
import 'models/variant.dart';
import 'network/dart_fetch_client.dart';
import 'network/dns_error_detector.dart';

/// Factory function type for creating [DartFetchClient] instances.
typedef DartFetchClientFactory = DartFetchClient Function({
  required String deploymentKey,
  required ExperimentConfig config,
});

/// An implementation of [AmplitudeExperimentsFlutterPlatform] that uses Pigeon.
class MethodChannelAmplitudeExperimentsFlutter
    extends AmplitudeExperimentsFlutterPlatform {
  /// Creates a new instance with an optional API for testing.
  ///
  /// [api] - Optional Pigeon API for testing.
  /// [dartFetchClientFactory] - Optional factory for creating DartFetchClient
  ///   instances. Used for testing the DNS fallback mechanism.
  MethodChannelAmplitudeExperimentsFlutter({
    AmplitudeExperimentsApi? api,
    @visibleForTesting DartFetchClientFactory? dartFetchClientFactory,
  })  : _api = api ?? AmplitudeExperimentsApi(),
        dartFetchClientFactory =
            dartFetchClientFactory ?? _defaultClientFactory;

  /// Default factory that creates real DartFetchClient instances.
  static DartFetchClient _defaultClientFactory({
    required String deploymentKey,
    required ExperimentConfig config,
  }) =>
      DartFetchClient(deploymentKey: deploymentKey, config: config);

  /// The Pigeon API used to interact with the native platform.
  @visibleForTesting
  AmplitudeExperimentsApi get api => _api;
  final AmplitudeExperimentsApi _api;

  /// Factory for creating DartFetchClient instances.
  final DartFetchClientFactory dartFetchClientFactory;

  /// Dart-based fetch client used as fallback when native SDK fails due to DNS issues.
  @visibleForTesting
  DartFetchClient? dartFetchClient;

  /// Stores the deployment key for creating the Dart fallback client.
  String? _deploymentKey;

  /// Stores the config for creating the Dart fallback client.
  ExperimentConfig? _config;

  /// Whether we're currently using the Dart fallback client.
  @visibleForTesting
  bool usingDartFallback = false;

  /// Completer to prevent multiple concurrent fetch calls from hitting native SDK.
  Completer<void>? _fetchCompleter;

  /// Lock object to synchronize fetch operations.
  /// When non-null, a fetch operation is in progress.
  Object? _fetchLock;

  @override
  Future<void> initialize(String deploymentKey, ExperimentConfig config) async {
    _deploymentKey = deploymentKey;
    _config = config;
    final configMessage = PigeonConverters.configToMessage(config);
    await api.initialize(deploymentKey, configMessage);
  }

  @override
  Future<void> initializeWithAmplitudeAnalytics(
    String deploymentKey,
    ExperimentConfig config,
  ) async {
    _deploymentKey = deploymentKey;
    _config = config;
    final configMessage = PigeonConverters.configToMessage(config);
    await api.initializeWithAmplitudeAnalytics(deploymentKey, configMessage);
  }

  @override
  Future<void> fetch(ExperimentUser? user) async {
    // If already using Dart fallback, continue using it
    if (usingDartFallback && dartFetchClient != null) {
      await dartFetchClient!.fetch(user);
      return;
    }

    // Check if there's already a fetch in progress (atomic check)
    final existingCompleter = _fetchCompleter;
    if (existingCompleter != null && !existingCompleter.isCompleted) {
      // Wait for the existing fetch to complete
      return existingCompleter.future;
    }

    // Use a lock object to prevent race conditions between the check above
    // and creating the new completer. If another call got here first,
    // wait for their completer instead.
    final lock = Object();
    if (_fetchLock != null) {
      // Another call won the race, wait for their completer
      final otherCompleter = _fetchCompleter;
      if (otherCompleter != null && !otherCompleter.isCompleted) {
        return otherCompleter.future;
      }
    }

    // Acquire the lock and create the completer atomically
    _fetchLock = lock;
    final completer = Completer<void>();
    _fetchCompleter = completer;

    try {
      final userMessage = PigeonConverters.userToMessage(user);
      await api.fetch(userMessage);
      completer.complete();
    } catch (e) {
      // Check if this is a DNS-related error
      if (DnsErrorDetector.isDnsRelatedError(e)) {
        debugPrint(
          '[AmplitudeExperiments] DNS error detected, falling back to Dart client',
        );
        try {
          await _fetchWithDartFallback(user);
          completer.complete();
        } catch (fallbackError) {
          completer.completeError(fallbackError);
          // Await the completer's future to properly propagate the error
          return completer.future;
        }
      } else {
        completer.completeError(e);
        // Await the completer's future to properly propagate the error
        return completer.future;
      }
    } finally {
      // Release the lock if we still own it
      if (_fetchLock == lock) {
        _fetchLock = null;
      }
    }
  }

  /// Fetches variants using the pure Dart client with custom DNS resolution.
  Future<void> _fetchWithDartFallback(ExperimentUser? user) async {
    final deploymentKey = _deploymentKey;
    final config = _config;

    if (deploymentKey == null || config == null) {
      throw StateError('Client not initialized. Call initialize() first.');
    }

    dartFetchClient ??= dartFetchClientFactory(
      deploymentKey: deploymentKey,
      config: config,
    );

    await dartFetchClient!.fetch(user);
    usingDartFallback = true;
  }

  @override
  Future<Variant?> variant(String key, Variant? fallback) async {
    // Wait for any in-progress fetch to complete before reading variants
    // This prevents calling native SDK while Dart fallback is being set up
    if (_fetchCompleter != null && !_fetchCompleter!.isCompleted) {
      try {
        await _fetchCompleter!.future;
      } catch (_) {
        // Fetch failed, return fallback
        return fallback;
      }
    }

    // If using Dart fallback, get from the Dart client
    if (usingDartFallback && dartFetchClient != null) {
      return dartFetchClient!.variant(key, fallback);
    }

    final fallbackMessage =
        fallback != null ? PigeonConverters.variantToMessage(fallback) : null;
    final result = await api.variant(key, fallbackMessage);
    return result != null ? PigeonConverters.variantFromMessage(result) : null;
  }

  @override
  Future<Map<String, Variant>> all() async {
    // Wait for any in-progress fetch to complete before reading variants
    if (_fetchCompleter != null && !_fetchCompleter!.isCompleted) {
      try {
        await _fetchCompleter!.future;
      } catch (_) {
        // Fetch failed, return empty map
        return {};
      }
    }

    // If using Dart fallback, get from the Dart client
    if (usingDartFallback && dartFetchClient != null) {
      return dartFetchClient!.all();
    }

    final result = await api.all();
    return PigeonConverters.variantMapFromMessages(result);
  }

  @override
  Future<void> exposure(String key) async {
    // Exposure tracking still goes through native SDK
    // (Dart fallback doesn't support exposure tracking)
    try {
      await api.exposure(key);
    } catch (_) {
      // Silently fail if native SDK is not working
      // Exposure tracking is not critical
    }
  }

  @override
  Future<void> clear() async {
    // Clear both native and Dart client
    dartFetchClient?.clear();
    usingDartFallback = false;
    _fetchCompleter = null;
    _fetchLock = null;

    try {
      await api.clear();
    } catch (_) {
      // Silently fail if native SDK is not working
    }
  }
}
