class KoozaDocument<T extends Object?> {
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

  const KoozaDocument._({
    required this.id,
    required this.data,
    required this.creationDate,
    required this.ttl,
  });

  factory KoozaDocument.fromDynamicData(KoozaDocument<dynamic>? doc) {
    if (doc == null) return KoozaDocument<T>.init();
    return KoozaDocument<T>._(
      id: doc.id,
      data: doc.data,
      creationDate: doc.creationDate,
      ttl: doc.ttl,
    );
  }

  factory KoozaDocument.init({
    String? id,
    T? data,
    DateTime? creationDate,
    Duration? ttl,
  }) {
    return KoozaDocument<T>._(
      id: id ?? '',
      data: data,
      creationDate: creationDate ?? DateTime.now(),
      ttl: ttl,
    );
  }

  KoozaDocument<T> copyWith({
    String? id,
    T? data,
    DateTime? creationDate,
    Duration? ttl,
  }) {
    return KoozaDocument<T>._(
      id: id ?? this.id,
      data: data ?? this.data,
      creationDate: creationDate ?? this.creationDate,
      ttl: ttl ?? this.ttl,
    );
  }

  factory KoozaDocument.fromMap(dynamic map) {
    if (map == null) return KoozaDocument<T>.init();
    final newMap = Map<String, dynamic>.from(map);
    return KoozaDocument<T>._(
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
      'creationDate': creationDate.toIso8601String(),
      'ttl': ttl?.inMilliseconds,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static T? _dataToType<T extends Object?>(dynamic data) {
    if (data == null) return null;
    if ('${data.runtimeType}'.contains('Map<dynamic, dynamic>') ||
        T == Map<String, dynamic>) {
      return Map<String, dynamic>.from(data) as T?;
    } else if ('${data.runtimeType}'.contains('List<dynamic>')) {
      var list = List<dynamic>.from(data);
      var listOfMap = <Map<String, dynamic>>[];
      var listOfDynamic = <dynamic>[];
      for (var e in list) {
        if ('${e.runtimeType}'.contains('Map<dynamic, dynamic>')) {
          listOfMap.add(Map<String, dynamic>.from(e));
        } else {
          listOfDynamic.add(e);
        }
      }
      if (listOfMap.isNotEmpty) return listOfMap as T?;
      return listOfDynamic as T?;
    }
    return data as T?;
  }

  static DateTime _toDateTime(dynamic creationDate) {
    return DateTime.tryParse(creationDate ?? '') ?? DateTime.now();
  }

  static Duration? _toDuration(dynamic ttl) {
    if (ttl == null) return null;
    final miliseconds = int.tryParse('$ttl');
    if (miliseconds == null) return null;
    return Duration(milliseconds: ttl);
  }
}
