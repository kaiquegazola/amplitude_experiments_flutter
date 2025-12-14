import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExperimentConfig', () {
    test('uses default values when not specified', () {
      const config = ExperimentConfig();

      expect(config.debug, false);
      expect(config.instanceName, isNull);
      expect(config.serverZone, ServerZone.us);
      expect(config.fetchTimeoutMillis, 10000);
      expect(config.retryFetchOnFailure, 1);
      expect(config.automaticExposureTracking, true);
      expect(config.fetchOnStart, false);
      expect(config.initialVariants, isNull);
    });

    test('accepts custom values', () {
      const config = ExperimentConfig(
        debug: true,
        instanceName: 'custom-instance',
        serverZone: ServerZone.eu,
        fetchTimeoutMillis: 5000,
        retryFetchOnFailure: 3,
        automaticExposureTracking: false,
        fetchOnStart: true,
      );

      expect(config.debug, true);
      expect(config.instanceName, 'custom-instance');
      expect(config.serverZone, ServerZone.eu);
      expect(config.fetchTimeoutMillis, 5000);
      expect(config.retryFetchOnFailure, 3);
      expect(config.automaticExposureTracking, false);
      expect(config.fetchOnStart, true);
    });

    test('accepts initial variants', () {
      const config = ExperimentConfig(
        initialVariants: {
          'feature-1': Variant(key: 'feature-1', value: 'on'),
          'feature-2': Variant(key: 'feature-2', value: 'off'),
        },
      );

      expect(config.initialVariants, isNotNull);
      expect(config.initialVariants!.length, 2);
      expect(config.initialVariants!['feature-1']!.isOn, true);
      expect(config.initialVariants!['feature-2']!.isOff, true);
    });

    test('toJson serializes all fields correctly', () {
      const config = ExperimentConfig(
        debug: true,
        instanceName: 'test-instance',
        serverZone: ServerZone.eu,
        fetchTimeoutMillis: 15000,
        retryFetchOnFailure: 2,
        automaticExposureTracking: false,
        fetchOnStart: true,
      );

      final json = config.toJson();

      expect(json['debug'], true);
      expect(json['instanceName'], 'test-instance');
      expect(json['serverZone'], 'eu');
      expect(json['fetchTimeoutMillis'], 15000);
      expect(json['retryFetchOnFailure'], 2);
      expect(json['automaticExposureTracking'], false);
      expect(json['fetchOnStart'], true);
    });

    test('toJson serializes initialVariants correctly', () {
      const config = ExperimentConfig(
        initialVariants: {
          'test-flag': Variant(key: 'test-flag', value: 'on'),
        },
      );

      final json = config.toJson();

      expect(json['initialVariants'], isNotNull);
      expect(json['initialVariants']['test-flag']['key'], 'test-flag');
      expect(json['initialVariants']['test-flag']['value'], 'on');
    });

    test('toString returns readable format', () {
      const config = ExperimentConfig(
        debug: true,
        serverZone: ServerZone.eu,
      );

      final str = config.toString();
      expect(str, contains('debug: true'));
      expect(str, contains('ServerZone.eu'));
    });
  });

  group('ServerZone', () {
    test('has us value', () {
      expect(ServerZone.us, isNotNull);
      expect(ServerZone.us.name, 'us');
    });

    test('has eu value', () {
      expect(ServerZone.eu, isNotNull);
      expect(ServerZone.eu.name, 'eu');
    });

    test('has exactly 2 values', () {
      expect(ServerZone.values.length, 2);
    });
  });
}
