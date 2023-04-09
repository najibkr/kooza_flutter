import 'kooza_collection.dart';
import 'kooza_document.dart';

class KoozaReference<Doc> {
  final Map<String, KoozaDocument<Doc>> _documents;
  final Map<String, KoozaCollection> _collections;
  const KoozaReference({
    Map<String, KoozaDocument<Doc>> documents = const {},
    Map<String, KoozaCollection> collections = const {},
  })  : _documents = documents,
        _collections = collections;

  KoozaDocument singleDoc(String docId) {
    return _documents[docId] ?? KoozaDocument.init();
  }

  KoozaCollection collection(String name) {
    return _collections[name] ?? const KoozaCollection.init();
  }

  Map<String, dynamic> toMap() {
    var data = <String, dynamic>{};
    data.addAll(_documents.map((key, value) => MapEntry(key, value.toMap())));
    data.addAll(_collections.map((key, value) => MapEntry(key, value.toMap())));
    return data;
  }
}
