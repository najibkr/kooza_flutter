class KoozaValue {
  final dynamic value;
  final DateTime timestamp;
  final Duration? ttl;

  const KoozaValue._({
    required this.value,
    required this.timestamp,
    required this.ttl,
  });

  factory KoozaValue.init({
    dynamic value,
    DateTime? timestamp,
    Duration? ttl,
  }) {
    return KoozaValue._(
      value: value,
      timestamp: timestamp ?? DateTime.now(),
      ttl: ttl,
    );
  }

  factory KoozaValue.fromMap(Map<String, dynamic> map) {
    return KoozaValue._(
      value: map['value'],
      timestamp: _toDateTime(map['timestamp']),
      ttl: _toDuration(map['ttl']),
    );
  }

  KoozaValue copyWith({
    dynamic value,
    DateTime? timestamp,
    Duration? ttl,
  }) {
    return KoozaValue._(
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl?.inMilliseconds,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static DateTime _toDateTime(dynamic timestamp) {
    return DateTime.tryParse(timestamp ?? '') ?? DateTime.now();
  }

  static Duration? _toDuration(dynamic ttl) {
    if (ttl == null) return null;
    final miliseconds = int.tryParse('$ttl');
    if (miliseconds == null) return null;
    return Duration(milliseconds: ttl);
  }
}
