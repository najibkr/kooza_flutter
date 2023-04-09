import 'kooza_document.dart';

class KoozaCollection<T extends Object?> {
  final Map<String, KoozaDocument<T>> docs;
  const KoozaCollection({required this.docs});
  const KoozaCollection.init({this.docs = const {}});

  KoozaDocument<T> doc(String id) {
    return docs[id] ?? KoozaDocument<T>.init();
  }

  List<KoozaDocument<T>> snapshots() {
    return docs.values.toList();
  }

  KoozaCollection<T> add(String id, T data, {Duration? ttl}) {
    var newDocs = Map<String, KoozaDocument<T>>.from(docs);
    var newDoc = KoozaDocument<T>.init(
      id: id,
      data: data,
      creationDate: DateTime.now(),
      ttl: ttl,
    );
    newDocs[id] = newDoc;
    return copyWith(docs: newDocs);
  }

  KoozaCollection<T> copyWith({
    Map<String, KoozaDocument<T>>? docs,
  }) {
    return KoozaCollection<T>(
      docs: docs ?? this.docs,
    );
  }

  factory KoozaCollection.fromMap(dynamic map) {
    if (map == null) return const KoozaCollection(docs: {});
    return KoozaCollection(
      docs: _toDocs(map),
    );
  }

  Map<String, dynamic> toMap() {
    return docs.map((key, value) => MapEntry(key, value.toMap()));
  }

  static Map<String, KoozaDocument<T>> _toDocs<T extends Object?>(
      dynamic data) {
    if (data == null) return <String, KoozaDocument<T>>{};
    final collection = Map<String, dynamic>.from(data);
    return collection.map((k, v) {
      if (v == null) return MapEntry(k, KoozaDocument<T>.fromMap(null));
      return MapEntry(
        k,
        KoozaDocument<T>.fromMap(Map<String, dynamic>.from(v)),
      );
    });
  }
}
