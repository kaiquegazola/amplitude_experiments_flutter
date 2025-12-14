/// Represents user context for experiment targeting
class ExperimentUser {
  const ExperimentUser({
    this.userId,
    this.deviceId,
    this.userProperties,
    this.groups,
    this.groupProperties,
  });

  /// Deserializes from JSON
  factory ExperimentUser.fromJson(Map<String, dynamic> json) => ExperimentUser(
        userId: json['userId'] as String?,
        deviceId: json['deviceId'] as String?,
        userProperties: json['userProperties'] as Map<String, dynamic>?,
        groups: json['groups'] as Map<String, dynamic>?,
        groupProperties:
            (json['groupProperties'] as Map<String, dynamic>?)?.map(
          (key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value as Map)),
        ),
      );

  /// User ID (persistent identifier)
  final String? userId;

  /// Device ID
  final String? deviceId;

  /// Custom user properties for targeting
  final Map<String, dynamic>? userProperties;

  /// Groups the user belongs to
  final Map<String, dynamic>? groups;

  /// Group properties
  final Map<String, Map<String, dynamic>>? groupProperties;

  /// Serializes to JSON
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'deviceId': deviceId,
        'userProperties': userProperties,
        'groups': groups,
        'groupProperties': groupProperties,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperimentUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          deviceId == other.deviceId;

  @override
  int get hashCode => Object.hash(userId, deviceId);

  @override
  String toString() => 'ExperimentUser(userId: $userId, deviceId: $deviceId)';
}
