import 'dart:math';

// import 'adapters/kooza_collection_reference_dep.dart';
import 'adapters/kooza_collection_reference.dart';
import 'adapters/kooza_impl.dart';
import 'adapters/kooza_single_document_reference.dart';

export 'domain/kooza_document.dart';
export 'domain/kooza_error.dart';

abstract class Kooza {
  const Kooza();

  /// Gets a singletone instance of [Kooza]
  static Future<Kooza> getInstance(String dbName) async {
    final Random rand = Random(DateTime.now().microsecond);
    return await KoozaImpl.getInstance(dbName, rand);
  }

  /// Create, read, update or delete a single document
  /// with any kind of data. The data type can only be
  /// flutter built-in types.
  KoozaSingleDocumentReference singleDoc(String documentName);

  /// Create, read, update or delete a collection
  /// with any kind of data. The data type can only be
  /// flutter built-in types.
  KoozaCollectionReference<Map<String, dynamic>> collection(
    String collectionName,
  );

  /// Clears The Database
  Future<void> clear();

  /// Clears all the open database instances
  Future<void> clearAll();

  /// Closes all the open boxes in the database
  Future<void> close();
}
