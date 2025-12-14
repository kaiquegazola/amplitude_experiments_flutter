import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// Android implementation of the amplitude_experiments_flutter plugin.
///
/// This class registers the Android platform implementation for the federated plugin.
/// The actual implementation is provided by the native Android code through Pigeon,
/// which is handled by [MethodChannelAmplitudeExperimentsFlutter].
class AmplitudeExperimentsFlutterAndroid
    extends MethodChannelAmplitudeExperimentsFlutter {
  /// Registers this class as the default instance of [AmplitudeExperimentsFlutterPlatform].
  static void registerWith() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      AmplitudeExperimentsFlutterPlatform.instance =
          AmplitudeExperimentsFlutterAndroid();
    }
  }
}
