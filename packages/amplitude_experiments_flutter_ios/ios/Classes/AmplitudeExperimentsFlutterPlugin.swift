import Flutter
import UIKit

/// Flutter plugin for Amplitude Experiments on iOS.
///
/// This plugin registers the Pigeon-generated API handler to enable
/// communication between Flutter and the native Amplitude Experiments SDK.
public class AmplitudeExperimentsFlutterPlugin: NSObject, FlutterPlugin {
    private var apiImpl: AmplitudeExperimentsApiImpl?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = AmplitudeExperimentsFlutterPlugin()
        instance.apiImpl = AmplitudeExperimentsApiImpl()
        AmplitudeExperimentsApiSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: instance.apiImpl
        )
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        AmplitudeExperimentsApiSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: nil
        )
        apiImpl = nil
    }
}
