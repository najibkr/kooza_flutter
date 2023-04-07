import 'kooza_document.dart';

class KoozaCollection {
  final Map<String, KoozaDocument> docs;

  KoozaDocument? doc(String id) {
    return docs[id];
  }

  List<Map<String, dynamic>> snapshots() {
    return docs.values.map((e) {
      return e.data ?? {};
    }).toList();
  }

  KoozaCollection setDoc(String id, KoozaDocument doc) {
    var newDocs = Map<String, KoozaDocument>.from(docs);
    newDocs[id] = doc;
    return copyWith(docs: newDocs);
  }

  const KoozaCollection({
    required this.docs,
  });

  const KoozaCollection.init({
    this.docs = const {},
  });

  factory KoozaCollection.fromMap(dynamic map) {
    return KoozaCollection(
      docs: _toDocs(map),
    );
  }

  KoozaCollection copyWith({
    Map<String, KoozaDocument>? docs,
  }) {
    return KoozaCollection(docs: docs ?? this.docs);
  }

  Map<String, dynamic> toMap() {
    return docs.map((key, value) => MapEntry(key, value.toMap()));
  }

  static Map<String, KoozaDocument> _toDocs(dynamic data) {
    if (data == null) return <String, KoozaDocument>{};
    final collection = Map<String, dynamic>.from(data);
    return collection.map((k, v) {
      if (v == null) return MapEntry(k, KoozaDocument.fromMap({}));
      return MapEntry(k, KoozaDocument.fromMap(Map<String, dynamic>.from(v)));
    });
  }
}
