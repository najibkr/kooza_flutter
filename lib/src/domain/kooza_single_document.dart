class KoozaSingleDocument<T extends Object?> {
  /// This document's given ID for this document.
  final String id;

  /// Contains all the data of this document snapshot.
  /// If the document does not exist, the returned data will be null.
  final T? data;

  /// The date that this document was created
  final DateTime creationDate;

  /// The assigned duration is how long the data will be stored kooza.
  final Duration? ttl;

  /// returns true if the document exists
  bool get exists => data != null;

  KoozaSingleDocument set(T data) => copyWith(data: data);

  const KoozaSingleDocument._({
    required this.id,
    required this.data,
    required this.creationDate,
    required this.ttl,
  });

  factory KoozaSingleDocument.init({
    String? id,
    T? data,
    DateTime? creationDate,
    Duration? ttl,
  }) {
    return KoozaSingleDocument._(
      id: id ?? '',
      data: data,
      creationDate: creationDate ?? DateTime.now(),
      ttl: ttl,
    );
  }

  KoozaSingleDocument copyWith({
    String? id,
    T? data,
    DateTime? creationDate,
    Duration? ttl,
  }) {
    return KoozaSingleDocument._(
      id: id ?? this.id,
      data: data ?? this.data,
      creationDate: creationDate ?? this.creationDate,
      ttl: ttl ?? this.ttl,
    );
  }

  factory KoozaSingleDocument.fromMap(dynamic map) {
    if (map == null) return KoozaSingleDocument.init();
    final newMap = Map<String, dynamic>.from(map);
    return KoozaSingleDocument<T>._(
      id: newMap['id'] ?? '',
      data: _dataToType<T>(newMap['data']),
      creationDate: _toDateTime(newMap['creationDate']),
      ttl: _toDuration(newMap['ttl']),
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'data': data,
      'creationDate': creationDate,
      'ttl': ttl?.inMilliseconds,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static T? _dataToType<T extends Object?>(dynamic data) {
    if (data == null) return null;
    if (T == Map<String, dynamic>) {
      return Map<String, dynamic>.from(data) as T?;
    }
    return data as T?;
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
