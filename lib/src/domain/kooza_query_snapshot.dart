import 'kooza_document.dart';

class KoozaQuerySnapshot<T extends Object?> {
  /// In `docs`, `key` is document name and `value` is the document
  final Map<String, KoozaDocument<T>> _docs;

  bool isEmpty() => _docs.isEmpty;

  List<KoozaDocument<T>> get docs => _docs.values.toList();

  bool docExists(String documentId) => _docs.containsKey(documentId);

  KoozaDocument<T> getDoc(String documentId) {
    return _docs[documentId] ?? KoozaDocument<T>.init();
  }

  KoozaQuerySnapshot<T> add(String id, KoozaDocument<T> document) {
    var docs = Map<String, KoozaDocument<T>>.from(_docs);
    docs[id] = document;
    return KoozaQuerySnapshot<T>(docs: docs);
  }

  KoozaQuerySnapshot<T> delete(String documentId) {
    var docs = Map<String, KoozaDocument<T>>.from(_docs);
    docs.removeWhere((key, value) => key == documentId);
    return KoozaQuerySnapshot<T>(docs: docs);
  }

  const KoozaQuerySnapshot({
    required Map<String, KoozaDocument<T>> docs,
  }) : _docs = docs;

  factory KoozaQuerySnapshot.init() {
    return KoozaQuerySnapshot<T>(docs: <String, KoozaDocument<T>>{});
  }

  factory KoozaQuerySnapshot.fromMap(dynamic map) {
    if (map == null) return KoozaQuerySnapshot<T>.init();
    var raw = Map<String, dynamic>.from(map);
    return KoozaQuerySnapshot<T>(
      docs: raw.map((k, v) => MapEntry(k, KoozaDocument<T>.fromMap(v))),
    );
  }

  Map<String, dynamic> toMap() {
    return _docs.map((key, value) => MapEntry(key, value.toMap()));
  }
}
