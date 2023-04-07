class KoozaDocument {
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final Duration? ttl;

  String? get docId => data?['docId'];

  const KoozaDocument._({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  factory KoozaDocument.init({
    required Map<String, dynamic>? data,
    DateTime? timestamp,
    Duration? ttl,
  }) {
    return KoozaDocument._(
      data: data,
      timestamp: timestamp ?? DateTime.now(),
      ttl: ttl,
    );
  }

  factory KoozaDocument.fromMap(Map<String, dynamic>? map) {
    return KoozaDocument._(
      data: _dataToMap(map?['data']),
      timestamp: _toDateTime(map?['timestamp']),
      ttl: _toDuration(map?['ttl']),
    );
  }

  KoozaDocument copyWith({
    Map<String, dynamic>? data,
    DateTime? timestamp,
    Duration? ttl,
  }) {
    return KoozaDocument._(
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl?.inMilliseconds,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static Map<String, dynamic>? _dataToMap(dynamic data) {
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
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
