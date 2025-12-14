import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Variant', () {
    test('isOn returns true when value is "on"', () {
      const variant = Variant(key: 'test', value: 'on');
      expect(variant.isOn, true);
      expect(variant.isOff, false);
    });

    test('isOff returns true when value is "off"', () {
      const variant = Variant(key: 'test', value: 'off');
      expect(variant.isOff, true);
      expect(variant.isOn, false);
    });

    test('isOff returns true when value is null', () {
      const variant = Variant(key: 'test');
      expect(variant.isOff, true);
      expect(variant.isOn, false);
    });

    test('toJson serializes all fields correctly', () {
      const variant = Variant(
        key: 'test-key',
        value: 'treatment',
        payload: {'color': 'blue', 'size': 10},
        expKey: 'exp-123',
      );

      final json = variant.toJson();

      expect(json['key'], 'test-key');
      expect(json['value'], 'treatment');
      expect(json['payload'], {'color': 'blue', 'size': 10});
      expect(json['expKey'], 'exp-123');
    });

    test('fromJson deserializes all fields correctly', () {
      final json = {
        'key': 'test-key',
        'value': 'control',
        'payload': {'enabled': true},
        'expKey': 'experiment-456',
      };

      final variant = Variant.fromJson(json);

      expect(variant.key, 'test-key');
      expect(variant.value, 'control');
      expect(variant.payload, {'enabled': true});
      expect(variant.expKey, 'experiment-456');
    });

    test('toJson and fromJson roundtrip preserves data', () {
      const original = Variant(
        key: 'roundtrip-test',
        value: 'variant-a',
        payload: ['item1', 'item2'],
        expKey: 'exp-roundtrip',
      );

      final json = original.toJson();
      final restored = Variant.fromJson(json);

      expect(restored.key, original.key);
      expect(restored.value, original.value);
      expect(restored.payload, original.payload);
      expect(restored.expKey, original.expKey);
    });

    test('handles null optional fields', () {
      const variant = Variant(key: 'minimal');

      expect(variant.key, 'minimal');
      expect(variant.value, isNull);
      expect(variant.payload, isNull);
      expect(variant.expKey, isNull);

      final json = variant.toJson();
      expect(json['key'], 'minimal');
      expect(json['value'], isNull);
    });

    test('equality works correctly', () {
      const variant1 = Variant(key: 'test', value: 'on', expKey: 'exp1');
      const variant2 = Variant(key: 'test', value: 'on', expKey: 'exp1');
      const variant3 = Variant(key: 'test', value: 'off', expKey: 'exp1');

      expect(variant1, equals(variant2));
      expect(variant1, isNot(equals(variant3)));
    });

    test('hashCode is consistent with equality', () {
      const variant1 = Variant(key: 'test', value: 'on', expKey: 'exp1');
      const variant2 = Variant(key: 'test', value: 'on', expKey: 'exp1');

      expect(variant1.hashCode, equals(variant2.hashCode));
    });

    test('toString returns readable format', () {
      const variant = Variant(key: 'test', value: 'on', expKey: 'exp1');

      expect(variant.toString(), contains('test'));
      expect(variant.toString(), contains('on'));
    });
  });
}
