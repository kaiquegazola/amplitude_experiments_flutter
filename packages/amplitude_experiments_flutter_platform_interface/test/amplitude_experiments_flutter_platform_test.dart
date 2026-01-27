import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAmplitudeExperimentsFlutterPlatform
    extends AmplitudeExperimentsFlutterPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<void> initialize(String deploymentKey, ExperimentConfig config) async {
    // Mock implementation
  }

  @override
  Future<void> initializeWithAmplitudeAnalytics(
    String deploymentKey,
    ExperimentConfig config,
  ) async {
    // Mock implementation
  }

  @override
  Future<void> fetch(ExperimentUser? user) async {
    // Mock implementation
  }

  @override
  Future<Variant?> variant(String key, Variant? fallback) async {
    return const Variant(key: 'test', value: 'on');
  }

  @override
  Future<Map<String, Variant>> all() async {
    return {'test': const Variant(key: 'test', value: 'on')};
  }

  @override
  Future<void> exposure(String key) async {
    // Mock implementation
  }

  @override
  Future<void> clear() async {
    // Mock implementation
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AmplitudeExperimentsFlutterPlatform', () {
    test('default instance is MethodChannelAmplitudeExperimentsFlutter', () {
      expect(
        AmplitudeExperimentsFlutterPlatform.instance,
        isA<MethodChannelAmplitudeExperimentsFlutter>(),
      );
    });

    test('can set custom instance', () {
      final mock = MockAmplitudeExperimentsFlutterPlatform();
      AmplitudeExperimentsFlutterPlatform.instance = mock;
      expect(AmplitudeExperimentsFlutterPlatform.instance, mock);

      // Reset to default
      AmplitudeExperimentsFlutterPlatform.instance =
          MethodChannelAmplitudeExperimentsFlutter();
    });

    test('initialize throws UnimplementedError by default', () {
      final platform = _TestPlatform();
      expect(
        () => platform.initialize('key', const ExperimentConfig()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test(
        'initializeWithAmplitudeAnalytics throws UnimplementedError by default',
        () {
      final platform = _TestPlatform();
      expect(
        () => platform.initializeWithAmplitudeAnalytics(
          'key',
          const ExperimentConfig(),
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('fetch throws UnimplementedError by default', () {
      final platform = _TestPlatform();
      expect(
        () => platform.fetch(null),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('variant throws UnimplementedError by default', () {
      final platform = _TestPlatform();
      expect(
        () => platform.variant('key', null),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('all throws UnimplementedError by default', () {
      final platform = _TestPlatform();
      expect(
        platform.all,
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('exposure throws UnimplementedError by default', () {
      final platform = _TestPlatform();
      expect(
        () => platform.exposure('key'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('clear throws UnimplementedError by default', () {
      final platform = _TestPlatform();
      expect(
        platform.clear,
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}

/// A test platform that exposes the default behavior without any overrides.
class _TestPlatform extends AmplitudeExperimentsFlutterPlatform
    with MockPlatformInterfaceMixin {}
