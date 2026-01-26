import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:amplitude_experiments_flutter_platform_interface/src/generated/messages.g.dart';
import 'package:amplitude_experiments_flutter_platform_interface/src/network/dart_fetch_client.dart';
import 'package:flutter/services.dart';
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

    group('DNS fallback', () {
      test('falls back to Dart client when DNS error occurs', () async {
        // First initialize to store config
        await methodChannel.initialize(
          'test-key',
          const ExperimentConfig(),
        );

        // Create a new mock that throws DNS error
        final failingApi = _DnsErrorThrowingApi();
        final failingChannel = MethodChannelAmplitudeExperimentsFlutter(
          api: failingApi,
        );

        // Initialize the failing channel
        await failingChannel.initialize(
          'test-key',
          const ExperimentConfig(fetchTimeoutMillis: 1000),
        );

        // fetch() should throw because Dart fallback will fail on network
        // but it should NOT throw PlatformException - it should try the fallback
        await expectLater(
          () => failingChannel.fetch(null),
          throwsA(isNot(isA<PlatformException>())),
        );
      });

      test('rethrows non-DNS errors', () async {
        final nonDnsErrorApi = _NonDnsErrorThrowingApi();
        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: nonDnsErrorApi,
        );

        await channel.initialize('test-key', const ExperimentConfig());

        await expectLater(
          () => channel.fetch(null),
          throwsA(isA<PlatformException>()),
        );
      });

      test('uses mock DartFetchClient when fallback is triggered', () async {
        final mockDartClient = MockDartFetchClient();
        final dnsErrorApi = _DnsErrorThrowingApi();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              mockDartClient,
        );

        await channel.initialize('test-key', const ExperimentConfig());
        await channel.fetch(null);

        expect(mockDartClient.fetchCalled, isTrue);
        expect(channel.usingDartFallback, isTrue);
      });

      test('variant returns from Dart client when using fallback', () async {
        final mockDartClient = MockDartFetchClient();
        mockDartClient.variants = {
          'test-flag': const Variant(key: 'test-flag', value: 'treatment'),
        };

        final dnsErrorApi = _DnsErrorThrowingApi();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              mockDartClient,
        );

        await channel.initialize('test-key', const ExperimentConfig());
        await channel.fetch(null);

        final result = await channel.variant('test-flag', null);

        expect(result?.value, 'treatment');
        expect(mockDartClient.variantCalled, isTrue);
      });

      test('all returns from Dart client when using fallback', () async {
        final mockDartClient = MockDartFetchClient();
        mockDartClient.variants = {
          'flag1': const Variant(key: 'flag1', value: 'on'),
          'flag2': const Variant(key: 'flag2', value: 'off'),
        };

        final dnsErrorApi = _DnsErrorThrowingApi();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              mockDartClient,
        );

        await channel.initialize('test-key', const ExperimentConfig());
        await channel.fetch(null);

        final result = await channel.all();

        expect(result.length, 2);
        expect(result['flag1']?.value, 'on');
        expect(result['flag2']?.value, 'off');
        expect(mockDartClient.allCalled, isTrue);
      });

      test('clear resets fallback state', () async {
        final mockDartClient = MockDartFetchClient();
        final dnsErrorApi = _DnsErrorThrowingApi();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              mockDartClient,
        );

        await channel.initialize('test-key', const ExperimentConfig());
        await channel.fetch(null);

        expect(channel.usingDartFallback, isTrue);

        await channel.clear();

        expect(channel.usingDartFallback, isFalse);
        expect(mockDartClient.clearCalled, isTrue);
      });

      test('continues using Dart client after fallback is activated', () async {
        final mockDartClient = MockDartFetchClient();
        final dnsErrorApi = _DnsErrorThrowingApi();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              mockDartClient,
        );

        await channel.initialize('test-key', const ExperimentConfig());

        // First fetch triggers fallback
        await channel.fetch(null);
        expect(mockDartClient.fetchCallCount, 1);

        // Second fetch should use Dart client directly
        await channel.fetch(null);
        expect(mockDartClient.fetchCallCount, 2);

        // Native API should not be called after fallback
        expect(dnsErrorApi.fetchCallCount, 1);
      });

      test('throws StateError when fetch called before initialize', () async {
        final dnsErrorApi = _DnsErrorThrowingApi();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              MockDartFetchClient(),
        );

        // Don't call initialize, fetch should throw StateError
        // because deploymentKey and config are null
        await expectLater(
          () => channel.fetch(null),
          throwsA(isA<StateError>()),
        );
      });

      test('variant returns fallback when fetch fails completely', () async {
        final dnsErrorApi = _DnsErrorThrowingApi();
        final failingDartClient = FailingMockDartFetchClient();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              failingDartClient,
        );

        await channel.initialize('test-key', const ExperimentConfig());

        // Start fetch in background (it will fail)
        final fetchFuture = channel.fetch(null);

        // Call variant while fetch is in progress
        const fallback = Variant(key: 'fallback', value: 'default');
        final resultFuture = channel.variant('test-flag', fallback);

        // Wait for fetch to complete (with error)
        await expectLater(fetchFuture, throwsException);

        // variant should return fallback because fetch failed
        final result = await resultFuture;
        expect(result, equals(fallback));
      });

      test('all returns empty map when fetch fails completely', () async {
        final dnsErrorApi = _DnsErrorThrowingApi();
        final failingDartClient = FailingMockDartFetchClient();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              failingDartClient,
        );

        await channel.initialize('test-key', const ExperimentConfig());

        // Start fetch (it will fail)
        final fetchFuture = channel.fetch(null);

        // Call all while fetch is in progress
        final resultFuture = channel.all();

        // Wait for fetch to complete (with error)
        await expectLater(fetchFuture, throwsException);

        // all should return empty map because fetch failed
        final result = await resultFuture;
        expect(result, isEmpty);
      });

      test('exposure still tries native SDK even when using fallback',
          () async {
        final mockDartClient = MockDartFetchClient();
        final dnsErrorApi = _DnsErrorThrowingApi();

        final channel = MethodChannelAmplitudeExperimentsFlutter(
          api: dnsErrorApi,
          dartFetchClientFactory: ({
            required String deploymentKey,
            required ExperimentConfig config,
          }) =>
              mockDartClient,
        );

        await channel.initialize('test-key', const ExperimentConfig());
        await channel.fetch(null);

        // Exposure should still try native SDK
        await channel.exposure('test-flag');

        expect(dnsErrorApi.exposureCalled, isTrue);
      });
    });
  });
}

/// Mock API that throws a DNS-related error on fetch.
class _DnsErrorThrowingApi extends MockAmplitudeExperimentsApi {
  int fetchCallCount = 0;

  @override
  Future<void> fetch(ExperimentUserMessage? user) async {
    fetchCallCount++;
    throw PlatformException(
      code: 'FETCH_ERROR',
      message: 'Failed to connect to api.lab.amplitude.com/[::]:443',
      details: 'Caused by: failed to connect to localhost/127.0.0.1 (port 443)',
    );
  }
}

/// Mock API that throws a non-DNS error on fetch.
class _NonDnsErrorThrowingApi extends MockAmplitudeExperimentsApi {
  @override
  Future<void> fetch(ExperimentUserMessage? user) async {
    throw PlatformException(
      code: 'FETCH_ERROR',
      message: 'HTTP 500 Internal Server Error',
    );
  }
}

/// Mock DartFetchClient for testing.
class MockDartFetchClient implements DartFetchClient {
  bool fetchCalled = false;
  bool variantCalled = false;
  bool allCalled = false;
  bool clearCalled = false;
  int fetchCallCount = 0;

  Map<String, Variant> variants = {};

  @override
  String get deploymentKey => 'test-key';

  @override
  ExperimentConfig get config => const ExperimentConfig();

  @override
  Future<void> fetch(ExperimentUser? user) async {
    fetchCalled = true;
    fetchCallCount++;
  }

  @override
  Variant? variant(String key, Variant? fallback) {
    variantCalled = true;
    return variants[key] ?? fallback;
  }

  @override
  Map<String, Variant> all() {
    allCalled = true;
    return Map.unmodifiable(variants);
  }

  @override
  void clear() {
    clearCalled = true;
    variants = {};
  }
}

/// Mock DartFetchClient that always fails.
class FailingMockDartFetchClient implements DartFetchClient {
  @override
  String get deploymentKey => 'test-key';

  @override
  ExperimentConfig get config => const ExperimentConfig();

  @override
  Future<void> fetch(ExperimentUser? user) async {
    throw Exception('Network error');
  }

  @override
  Variant? variant(String key, Variant? fallback) => fallback;

  @override
  Map<String, Variant> all() => {};

  @override
  void clear() {}
}
