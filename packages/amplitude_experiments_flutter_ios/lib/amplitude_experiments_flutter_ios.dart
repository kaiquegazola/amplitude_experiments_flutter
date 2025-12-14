import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// iOS implementation of the amplitude_experiments_flutter plugin.
///
/// This class registers the iOS platform implementation for the federated plugin.
/// The actual implementation is provided by the native iOS code through Pigeon,
/// which is handled by [MethodChannelAmplitudeExperimentsFlutter].
class AmplitudeExperimentsFlutterIOS
    extends MethodChannelAmplitudeExperimentsFlutter {
  /// Registers this class as the default instance of [AmplitudeExperimentsFlutterPlatform].
  static void registerWith() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      AmplitudeExperimentsFlutterPlatform.instance =
          AmplitudeExperimentsFlutterIOS();
    }
  }
}
