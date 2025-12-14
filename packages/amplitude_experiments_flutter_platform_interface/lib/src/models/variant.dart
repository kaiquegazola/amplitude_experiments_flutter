/// Represents an experiment/feature flag variant
class Variant {
  const Variant({
    required this.key,
    this.value,
    this.payload,
    this.expKey,
  });

  /// Deserializes from JSON
  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
        key: json['key'] as String,
        value: json['value'] as String?,
        payload: json['payload'],
        expKey: json['expKey'] as String?,
      );

  /// Variant identifier key
  final String key;

  /// Variant value (typically 'on', 'off', or null)
  final String? value;

  /// Optional JSON payload with additional data
  final dynamic payload;

  /// Experiment key for exposure tracking
  final String? expKey;

  /// Returns true if value is 'on'
  bool get isOn => value == 'on';

  /// Returns true if value is 'off' or null
  bool get isOff => value == 'off' || value == null;

  /// Serializes to JSON
  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'payload': payload,
        'expKey': expKey,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Variant &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value &&
          expKey == other.expKey;

  @override
  int get hashCode => Object.hash(key, value, expKey);

  @override
  String toString() => 'Variant(key: $key, value: $value, expKey: $expKey)';
}
