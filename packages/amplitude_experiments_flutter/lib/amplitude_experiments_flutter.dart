/// Amplitude Experiments SDK for Flutter.
///
/// This library provides feature flags and A/B testing capabilities
/// through the Amplitude Experiments platform.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:amplitude_experiments_flutter/amplitude_experiments_flutter.dart';
///
/// // Initialize the client
/// await AmplitudeExperiments.initialize('YOUR-DEPLOYMENT-KEY');
///
/// // Fetch variants for a user
/// await AmplitudeExperiments.fetch(ExperimentUser(userId: 'user-123'));
///
/// // Get a variant
/// final variant = await AmplitudeExperiments.variant('my-feature-flag');
/// ```
library;

// Re-export public types from platform interface
export 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart'
    show ExperimentConfig, ExperimentUser, ServerZone, Variant;

export 'src/amplitude_experiments.dart';
