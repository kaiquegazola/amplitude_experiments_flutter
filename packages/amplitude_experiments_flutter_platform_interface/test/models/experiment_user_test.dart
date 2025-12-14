import 'package:amplitude_experiments_flutter_platform_interface/amplitude_experiments_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExperimentUser', () {
    test('creates user with all properties', () {
      const user = ExperimentUser(
        userId: 'user-123',
        deviceId: 'device-456',
        userProperties: {'plan': 'premium', 'age': 25},
        groups: {'company': 'acme', 'team': 'engineering'},
        groupProperties: {
          'company': {'industry': 'tech', 'size': 100},
        },
      );

      expect(user.userId, 'user-123');
      expect(user.deviceId, 'device-456');
      expect(user.userProperties, {'plan': 'premium', 'age': 25});
      expect(user.groups, {'company': 'acme', 'team': 'engineering'});
      expect(user.groupProperties!['company']!['industry'], 'tech');
    });

    test('creates user with minimal properties', () {
      const user = ExperimentUser(userId: 'user-only');

      expect(user.userId, 'user-only');
      expect(user.deviceId, isNull);
      expect(user.userProperties, isNull);
      expect(user.groups, isNull);
      expect(user.groupProperties, isNull);
    });

    test('creates empty user', () {
      const user = ExperimentUser();

      expect(user.userId, isNull);
      expect(user.deviceId, isNull);
      expect(user.userProperties, isNull);
      expect(user.groups, isNull);
      expect(user.groupProperties, isNull);
    });

    test('toJson includes all properties', () {
      const user = ExperimentUser(
        userId: 'user-123',
        deviceId: 'device-456',
        userProperties: {'plan': 'premium'},
        groups: {'company': 'acme'},
        groupProperties: {
          'company': {'size': 50},
        },
      );

      final json = user.toJson();

      expect(json['userId'], 'user-123');
      expect(json['deviceId'], 'device-456');
      expect(json['userProperties'], {'plan': 'premium'});
      expect(json['groups'], {'company': 'acme'});
      expect(json['groupProperties'], {
        'company': {'size': 50},
      });
    });

    test('toJson handles null properties', () {
      const user = ExperimentUser(userId: 'user-123');

      final json = user.toJson();

      expect(json['userId'], 'user-123');
      expect(json['deviceId'], isNull);
      expect(json['userProperties'], isNull);
      expect(json['groups'], isNull);
      expect(json['groupProperties'], isNull);
    });

    test('fromJson deserializes all fields correctly', () {
      final json = {
        'userId': 'user-789',
        'deviceId': 'device-012',
        'userProperties': {'tier': 'gold'},
        'groups': {'org': 'startup'},
        'groupProperties': {
          'org': {'founded': 2020},
        },
      };

      final user = ExperimentUser.fromJson(json);

      expect(user.userId, 'user-789');
      expect(user.deviceId, 'device-012');
      expect(user.userProperties, {'tier': 'gold'});
      expect(user.groups, {'org': 'startup'});
      expect(user.groupProperties!['org']!['founded'], 2020);
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{
        'userId': null,
        'deviceId': 'device-only',
      };

      final user = ExperimentUser.fromJson(json);

      expect(user.userId, isNull);
      expect(user.deviceId, 'device-only');
    });

    test('toJson and fromJson roundtrip preserves data', () {
      const original = ExperimentUser(
        userId: 'roundtrip-user',
        deviceId: 'roundtrip-device',
        userProperties: {'key': 'value'},
        groups: {'group': 'test'},
        groupProperties: {
          'group': {'prop': 'val'},
        },
      );

      final json = original.toJson();
      final restored = ExperimentUser.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.deviceId, original.deviceId);
      expect(restored.userProperties, original.userProperties);
      expect(restored.groups, original.groups);
      expect(restored.groupProperties, original.groupProperties);
    });

    test('equality works correctly', () {
      const user1 = ExperimentUser(userId: 'user-1', deviceId: 'device-1');
      const user2 = ExperimentUser(userId: 'user-1', deviceId: 'device-1');
      const user3 = ExperimentUser(userId: 'user-2', deviceId: 'device-1');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('hashCode is consistent with equality', () {
      const user1 = ExperimentUser(userId: 'user-1', deviceId: 'device-1');
      const user2 = ExperimentUser(userId: 'user-1', deviceId: 'device-1');

      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('toString returns readable format', () {
      const user = ExperimentUser(userId: 'user-123', deviceId: 'device-456');

      expect(user.toString(), contains('user-123'));
      expect(user.toString(), contains('device-456'));
    });
  });
}
