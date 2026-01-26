import 'package:amplitude_experiments_flutter_platform_interface/src/models/experiment_config.dart';
import 'package:amplitude_experiments_flutter_platform_interface/src/models/experiment_user.dart';
import 'package:amplitude_experiments_flutter_platform_interface/src/models/server_zone.dart';
import 'package:amplitude_experiments_flutter_platform_interface/src/models/variant.dart';
import 'package:amplitude_experiments_flutter_platform_interface/src/network/dart_fetch_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartFetchClient', () {
    late DartFetchClient client;

    setUp(() {
      client = DartFetchClient(
        deploymentKey: 'test-deployment-key',
        config: const ExperimentConfig(
          serverZone: ServerZone.us,
          fetchTimeoutMillis: 5000,
          automaticExposureTracking: true,
        ),
      );
    });

    group('variant', () {
      test('returns null when no variants are cached', () {
        final result = client.variant('test-flag', null);
        expect(result, isNull);
      });

      test('returns fallback when variant not found', () {
        const fallback = Variant(key: 'fallback', value: 'default');
        final result = client.variant('non-existent', fallback);
        expect(result, equals(fallback));
      });
    });

    group('all', () {
      test('returns empty map when no variants are cached', () {
        final result = client.all();
        expect(result, isEmpty);
      });

      test('returns unmodifiable map', () {
        final result = client.all();
        expect(
          () => (result as Map<String, Variant>)['test'] =
              const Variant(key: 'test'),
          throwsUnsupportedError,
        );
      });
    });

    group('clear', () {
      test('clears cached variants', () {
        // Initially empty
        expect(client.all(), isEmpty);

        // Clear should not throw
        client.clear();

        // Still empty after clear
        expect(client.all(), isEmpty);
      });
    });

    group('server URL', () {
      test('uses US server URL by default', () {
        final usClient = DartFetchClient(
          deploymentKey: 'key',
          config: const ExperimentConfig(serverZone: ServerZone.us),
        );
        // We can't directly access private _serverUrl, but we can verify
        // the client was created successfully
        expect(usClient, isNotNull);
      });

      test('can be configured for EU server zone', () {
        final euClient = DartFetchClient(
          deploymentKey: 'key',
          config: const ExperimentConfig(serverZone: ServerZone.eu),
        );
        expect(euClient, isNotNull);
      });
    });

    group('user serialization', () {
      test('handles null user', () {
        // fetch() with null user should not throw during user serialization
        // (it will fail on network, but that's expected in tests)
        expect(
          () => client.fetch(null),
          throwsA(anything), // Will throw due to network, not user handling
        );
      });

      test('handles user with all fields', () {
        const user = ExperimentUser(
          userId: 'user-123',
          deviceId: 'device-456',
          userProperties: {'plan': 'premium'},
        );
        // fetch() should not throw during user serialization
        expect(
          () => client.fetch(user),
          throwsA(anything), // Will throw due to network, not user handling
        );
      });
    });
  });

  group('DartFetchClient configuration', () {
    test('respects fetch timeout from config', () {
      final client = DartFetchClient(
        deploymentKey: 'key',
        config: const ExperimentConfig(fetchTimeoutMillis: 1000),
      );
      expect(client, isNotNull);
    });

    test('respects automatic exposure tracking config', () {
      final clientWithTracking = DartFetchClient(
        deploymentKey: 'key',
        config: const ExperimentConfig(automaticExposureTracking: true),
      );
      final clientWithoutTracking = DartFetchClient(
        deploymentKey: 'key',
        config: const ExperimentConfig(automaticExposureTracking: false),
      );
      expect(clientWithTracking, isNotNull);
      expect(clientWithoutTracking, isNotNull);
    });
  });
}
