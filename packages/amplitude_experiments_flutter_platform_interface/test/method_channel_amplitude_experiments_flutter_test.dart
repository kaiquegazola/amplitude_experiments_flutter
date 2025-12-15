import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:amplitude_experiments_flutter_platform_interface/src/generated/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mock implementation of [AmplitudeExperimentsApi] for testing.
class MockAmplitudeExperimentsApi extends AmplitudeExperimentsApi {
  MockAmplitudeExperimentsApi() : super();
  bool initializeCalled = false;
  bool initializeWithAnalyticsCalled = false;
  bool fetchCalled = false;
  bool variantCalled = false;
  bool allCalled = false;
  bool exposureCalled = false;
  bool clearCalled = false;

  String? lastDeploymentKey;
  ExperimentConfigMessage? lastConfig;
  ExperimentUserMessage? lastUser;
  String? lastVariantKey;
  VariantMessage? lastFallback;
  String? lastExposureKey;

  VariantMessage? variantResult;
  Map<String, VariantMessage?> allResult = {};

  @override
  Future<void> initialize(
    String deploymentKey,
    ExperimentConfigMessage config,
  ) async {
    initializeCalled = true;
    lastDeploymentKey = deploymentKey;
    lastConfig = config;
  }

  @override
  Future<void> initializeWithAmplitudeAnalytics(
    String deploymentKey,
    ExperimentConfigMessage config,
  ) async {
    initializeWithAnalyticsCalled = true;
    lastDeploymentKey = deploymentKey;
    lastConfig = config;
  }

  @override
  Future<void> fetch(ExperimentUserMessage? user) async {
    fetchCalled = true;
    lastUser = user;
  }

  @override
  Future<VariantMessage?> variant(String key, VariantMessage? fallback) async {
    variantCalled = true;
    lastVariantKey = key;
    lastFallback = fallback;
    return variantResult;
  }

  @override
  Future<Map<String, VariantMessage?>> all() async {
    allCalled = true;
    return allResult;
  }

  @override
  Future<void> exposure(String key) async {
    exposureCalled = true;
    lastExposureKey = key;
  }

  @override
  Future<void> clear() async {
    clearCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAmplitudeExperimentsApi mockApi;
  late MethodChannelAmplitudeExperimentsFlutter methodChannel;

  setUp(() {
    mockApi = MockAmplitudeExperimentsApi();
    methodChannel = MethodChannelAmplitudeExperimentsFlutter(api: mockApi);
  });

  group('MethodChannelAmplitudeExperimentsFlutter', () {
    group('initialize', () {
      test('calls api.initialize with correct parameters', () async {
        const config = ExperimentConfig(
          debug: true,
          serverZone: ServerZone.eu,
          fetchTimeoutMillis: 5000,
        );

        await methodChannel.initialize('test-key', config);

        expect(mockApi.initializeCalled, isTrue);
        expect(mockApi.lastDeploymentKey, 'test-key');
        expect(mockApi.lastConfig?.debug, isTrue);
        expect(mockApi.lastConfig?.serverZone, ServerZoneMessage.eu);
        expect(mockApi.lastConfig?.fetchTimeoutMillis, 5000);
      });
    });

    group('initializeWithAmplitudeAnalytics', () {
      test('calls api.initializeWithAmplitudeAnalytics with correct parameters',
          () async {
        const config = ExperimentConfig(debug: false);

        await methodChannel.initializeWithAmplitudeAnalytics(
            'analytics-key', config);

        expect(mockApi.initializeWithAnalyticsCalled, isTrue);
        expect(mockApi.lastDeploymentKey, 'analytics-key');
        expect(mockApi.lastConfig?.debug, isFalse);
      });
    });

    group('fetch', () {
      test('calls api.fetch with user', () async {
        const user = ExperimentUser(
          userId: 'user-123',
          deviceId: 'device-456',
        );

        await methodChannel.fetch(user);

        expect(mockApi.fetchCalled, isTrue);
        expect(mockApi.lastUser?.userId, 'user-123');
        expect(mockApi.lastUser?.deviceId, 'device-456');
      });

      test('calls api.fetch with null user', () async {
        await methodChannel.fetch(null);

        expect(mockApi.fetchCalled, isTrue);
        expect(mockApi.lastUser, isNull);
      });
    });

    group('variant', () {
      test('returns variant from api', () async {
        mockApi.variantResult = VariantMessage(
          key: 'test-flag',
          value: 'treatment',
          payload: {'color': 'blue'},
          expKey: 'exp-123',
        );

        final result = await methodChannel.variant('test-flag', null);

        expect(mockApi.variantCalled, isTrue);
        expect(mockApi.lastVariantKey, 'test-flag');
        expect(result?.key, 'test-flag');
        expect(result?.value, 'treatment');
        expect(result?.payload, {'color': 'blue'});
        expect(result?.expKey, 'exp-123');
      });

      test('returns null when api returns null', () async {
        mockApi.variantResult = null;

        final result = await methodChannel.variant('missing-flag', null);

        expect(result, isNull);
      });

      test('passes fallback to api', () async {
        const fallback = Variant(key: 'fallback', value: 'off');

        await methodChannel.variant('test-flag', fallback);

        expect(mockApi.lastFallback?.key, 'fallback');
        expect(mockApi.lastFallback?.value, 'off');
      });
    });

    group('all', () {
      test('returns all variants from api', () async {
        mockApi.allResult = {
          'flag1': VariantMessage(key: 'flag1', value: 'on'),
          'flag2': VariantMessage(key: 'flag2', value: 'off'),
        };

        final result = await methodChannel.all();

        expect(mockApi.allCalled, isTrue);
        expect(result.length, 2);
        expect(result['flag1']?.value, 'on');
        expect(result['flag2']?.value, 'off');
      });

      test('returns empty map when api returns empty', () async {
        mockApi.allResult = {};

        final result = await methodChannel.all();

        expect(result, isEmpty);
      });
    });

    group('exposure', () {
      test('calls api.exposure with correct key', () async {
        await methodChannel.exposure('tracked-flag');

        expect(mockApi.exposureCalled, isTrue);
        expect(mockApi.lastExposureKey, 'tracked-flag');
      });
    });

    group('clear', () {
      test('calls api.clear', () async {
        await methodChannel.clear();

        expect(mockApi.clearCalled, isTrue);
      });
    });
  });
}
