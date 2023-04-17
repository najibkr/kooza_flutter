import 'kooza_document.dart';

class KoozaCollection<T extends Object?> {
  final KoozaQuery<Map<String, dynamic>> _query;
  final Map<String, KoozaDocument<T>> docs;

  /// In `docs`, `key` is the collection name and `value` is the document
  const KoozaCollection({
    required this.docs,
    // required Map<String, KoozaDocument<T>> docs,
    required KoozaQuery<Map<String, dynamic>> query,
  }) : // _docs = docs,
        _query = query;

  factory KoozaCollection.init() {
    return KoozaCollection<T>(
      docs: <String, KoozaDocument<T>>{},
      query: const KoozaQuery<Map<String, dynamic>>({}),
    );
  }

  KoozaQuery<Map<String, dynamic>> where(String fieldName, bool isEqualTo, String value) {
    var query = Map<String, dynamic>.from(_query.query);
    query[fieldName] = value;
    return _query.copyWith(query);
  }

  factory KoozaCollection.fromMap(dynamic map) {
    if (map == null) return KoozaCollection<T>.init();
    var raw = Map<String, dynamic>.from(map);
    return KoozaCollection<T>(
      query: const KoozaQuery<Map<String, dynamic>>({}),
      docs: raw.map((k, v) => MapEntry(k, KoozaDocument<T>.fromMap(v))),
    );
  }

  Map<String, dynamic> toMap() {
    return docs.map((key, value) => MapEntry(key, value.toMap()));
  }
}

class KoozaQuery<T extends Object?> {
  final T query;
  const KoozaQuery(this.query);

  KoozaQuery<T> copyWith(T? query) {
    return KoozaQuery<T>(query ?? this.query);
  }
}
