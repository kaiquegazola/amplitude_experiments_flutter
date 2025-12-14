import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PigeonConverters - Variant', () {
    test('variantFromMessage converts all fields correctly', () {
      final message = VariantMessage(
        key: 'test-key',
        value: 'on',
        payload: {'color': 'blue'},
        expKey: 'exp-123',
      );

      final variant = PigeonConverters.variantFromMessage(message);

      expect(variant.key, 'test-key');
      expect(variant.value, 'on');
      expect(variant.payload, {'color': 'blue'});
      expect(variant.expKey, 'exp-123');
    });

    test('variantToMessage converts all fields correctly', () {
      const variant = Variant(
        key: 'test-key',
        value: 'off',
        payload: ['item1', 'item2'],
        expKey: 'exp-456',
      );

      final message = PigeonConverters.variantToMessage(variant);

      expect(message.key, 'test-key');
      expect(message.value, 'off');
      expect(message.payload, ['item1', 'item2']);
      expect(message.expKey, 'exp-456');
    });

    test('variant roundtrip preserves data', () {
      const original = Variant(
        key: 'roundtrip',
        value: 'treatment',
        payload: {
          'nested': {'key': 'value'},
        },
        expKey: 'exp-roundtrip',
      );

      final message = PigeonConverters.variantToMessage(original);
      final restored = PigeonConverters.variantFromMessage(message);

      expect(restored.key, original.key);
      expect(restored.value, original.value);
      expect(restored.payload, original.payload);
      expect(restored.expKey, original.expKey);
    });

    test('handles null optional fields', () {
      final message = VariantMessage(key: 'minimal');

      final variant = PigeonConverters.variantFromMessage(message);

      expect(variant.key, 'minimal');
      expect(variant.value, isNull);
      expect(variant.payload, isNull);
      expect(variant.expKey, isNull);
    });
  });

  group('PigeonConverters - ExperimentUser', () {
    test('userToMessage returns null for null input', () {
      final result = PigeonConverters.userToMessage(null);
      expect(result, isNull);
    });

    test('userToMessage converts all fields correctly', () {
      const user = ExperimentUser(
        userId: 'user-123',
        deviceId: 'device-456',
        userProperties: {'plan': 'premium'},
        groups: {'company': 'acme'},
        groupProperties: {
          'company': {'size': 100},
        },
      );

      final message = PigeonConverters.userToMessage(user);

      expect(message, isNotNull);
      expect(message!.userId, 'user-123');
      expect(message.deviceId, 'device-456');
      expect(message.userProperties, {'plan': 'premium'});
      expect(message.groups, {'company': 'acme'});
      expect(message.groupProperties, {
        'company': {'size': 100},
      });
    });

    test('userToMessage handles minimal user', () {
      const user = ExperimentUser(userId: 'user-only');

      final message = PigeonConverters.userToMessage(user);

      expect(message, isNotNull);
      expect(message!.userId, 'user-only');
      expect(message.deviceId, isNull);
      expect(message.userProperties, isNull);
    });

    test('userFromMessage returns null for null input', () {
      final result = PigeonConverters.userFromMessage(null);
      expect(result, isNull);
    });

    test('userFromMessage converts all fields correctly', () {
      final message = ExperimentUserMessage(
        userId: 'user-789',
        deviceId: 'device-012',
        userProperties: {'tier': 'gold'},
        groups: {'org': 'startup'},
      );

      final user = PigeonConverters.userFromMessage(message);

      expect(user, isNotNull);
      expect(user!.userId, 'user-789');
      expect(user.deviceId, 'device-012');
      expect(user.userProperties, {'tier': 'gold'});
      expect(user.groups, {'org': 'startup'});
    });
  });

  group('PigeonConverters - ServerZone', () {
    test('serverZoneToMessage converts US correctly', () {
      final message = PigeonConverters.serverZoneToMessage(ServerZone.us);
      expect(message, ServerZoneMessage.us);
    });

    test('serverZoneToMessage converts EU correctly', () {
      final message = PigeonConverters.serverZoneToMessage(ServerZone.eu);
      expect(message, ServerZoneMessage.eu);
    });

    test('serverZoneFromMessage converts US correctly', () {
      final zone = PigeonConverters.serverZoneFromMessage(ServerZoneMessage.us);
      expect(zone, ServerZone.us);
    });

    test('serverZoneFromMessage converts EU correctly', () {
      final zone = PigeonConverters.serverZoneFromMessage(ServerZoneMessage.eu);
      expect(zone, ServerZone.eu);
    });
  });

  group('PigeonConverters - ExperimentConfig', () {
    test('configToMessage converts default config correctly', () {
      const config = ExperimentConfig();

      final message = PigeonConverters.configToMessage(config);

      expect(message.debug, false);
      expect(message.instanceName, isNull);
      expect(message.serverZone, ServerZoneMessage.us);
      expect(message.fetchTimeoutMillis, 10000);
      expect(message.retryFetchOnFailure, 1);
      expect(message.automaticExposureTracking, true);
      expect(message.fetchOnStart, false);
      expect(message.initialVariants, isNull);
    });

    test('configToMessage converts custom config correctly', () {
      const config = ExperimentConfig(
        debug: true,
        instanceName: 'test-instance',
        serverZone: ServerZone.eu,
        fetchTimeoutMillis: 5000,
        retryFetchOnFailure: 3,
        automaticExposureTracking: false,
        fetchOnStart: true,
      );

      final message = PigeonConverters.configToMessage(config);

      expect(message.debug, true);
      expect(message.instanceName, 'test-instance');
      expect(message.serverZone, ServerZoneMessage.eu);
      expect(message.fetchTimeoutMillis, 5000);
      expect(message.retryFetchOnFailure, 3);
      expect(message.automaticExposureTracking, false);
      expect(message.fetchOnStart, true);
    });

    test('configToMessage converts initialVariants correctly', () {
      const config = ExperimentConfig(
        initialVariants: {
          'feature-1': Variant(key: 'feature-1', value: 'on'),
          'feature-2': Variant(key: 'feature-2', value: 'off'),
        },
      );

      final message = PigeonConverters.configToMessage(config);

      expect(message.initialVariants, isNotNull);
      expect(message.initialVariants!.length, 2);
      expect(message.initialVariants!['feature-1']!.value, 'on');
      expect(message.initialVariants!['feature-2']!.value, 'off');
    });
  });

  group('PigeonConverters - Map Conversions', () {
    test('variantMapFromMessages converts map correctly', () {
      final messages = <String?, VariantMessage?>{
        'flag-1': VariantMessage(key: 'flag-1', value: 'on'),
        'flag-2': VariantMessage(key: 'flag-2', value: 'off'),
      };

      final variants = PigeonConverters.variantMapFromMessages(messages);

      expect(variants.length, 2);
      expect(variants['flag-1']!.isOn, true);
      expect(variants['flag-2']!.isOff, true);
    });

    test('variantMapFromMessages handles empty map', () {
      final messages = <String?, VariantMessage?>{};

      final variants = PigeonConverters.variantMapFromMessages(messages);

      expect(variants, isEmpty);
    });

    test('variantMapFromMessages throws on null message', () {
      final messages = <String?, VariantMessage?>{
        'flag-1': VariantMessage(key: 'flag-1', value: 'on'),
        'flag-2': null,
      };

      expect(
        () => PigeonConverters.variantMapFromMessages(messages),
        throwsArgumentError,
      );
    });

    test('variantMapToMessages converts map correctly', () {
      final variants = <String, Variant>{
        'flag-1': const Variant(key: 'flag-1', value: 'on'),
        'flag-2': const Variant(key: 'flag-2', value: 'off'),
      };

      final messages = PigeonConverters.variantMapToMessages(variants);

      expect(messages.length, 2);
      expect(messages['flag-1']!.value, 'on');
      expect(messages['flag-2']!.value, 'off');
    });

    test('variantMapToMessages handles empty map', () {
      final variants = <String, Variant>{};

      final messages = PigeonConverters.variantMapToMessages(variants);

      expect(messages, isEmpty);
    });
  });
}
