import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';

import 'adapters/kooza_collection_reference.dart';
import 'adapters/kooza_impl.dart';
import 'adapters/kooza_single_document_reference.dart';

export 'domain/kooza_document.dart';
export 'domain/kooza_error.dart';

abstract class Kooza {
  /// This must be run inside main or the
  /// database will not work.
  static Future<void> ensureInitialize() async {
    try {
      await Hive.initFlutter('kooza');
    } catch (e) {
      if (kDebugMode) print('Error Initializing Kooza $e');
    }
  }

  /// Initializes an instance of Kooza.
  /// Please remember to close it when you are not using it.
  static Kooza instance(
    String dbName, {
    String path = 'kooza',
  }) {
    return KoozaImpl.init(dbName);
  }

  /// Create, read, update or delete a single document
  /// with any kind of data. The data type can only be
  /// flutter built-in types.
  KoozaSingleDocumentReference singleDoc(String key);

  /// Create, read, update or delete a collection
  /// with any kind of data. The data type can only be
  /// flutter built-in types.
  KoozaCollectionReference<Map<String, dynamic>> collection(
    String collectionName,
  );

  // / Saves the [bool] `value` in memory with the assigned `key`.
  // / Use `ttl` to determine how long should the `value` remain in memory.
  // / If no `ttl` is `null`, the `value` will permanently be
  // / stored in the device memory with the assigned `key`.
  // Future<void> setBool(
  //   String key,
  //   bool? value, {
  //   Duration? ttl,
  // });

  // / Reactively reads the stored boolean with the given `key`.
  // / If no boolean value is saved, the returned value will be `null`.
  // Stream<bool?> streamBool(String key);

  // / Asynchronously reads the stored boolean with the given `key`.
  // / If no boolean value is saved, the returned value will be `null`.
  // Future<bool?> fetchBool(String key);

  // / Saves the [int] `value` in memory with the assigned `key`.
  // / Use `ttl` to determine how long should the `value` remain in memory.
  // / If `ttl` is `null`, the `value` will permanently be
  // / stored in the device memory with the assigned `key`.
  // Future<void> setInt(
  //   String key,
  //   int? value, {
  //   Duration? ttl,
  // });

  // / Reactively reads the stored int with the given `key`.
  // / If no boolean value is saved, the returned value will be `null`.
  // Stream<int?> streamInt(String key);

  // / Saves the [double] `value` in memory with the assigned `key`.
  // / Use `ttl` to determine how long should the `value` remain in memory.
  // / If `ttl` is `null`, the `value` will permanently be
  // / stored in the device memory with the assigned `key`.
  // Future<void> setDouble(
  //   String key,
  //   double? value, {
  //   Duration? ttl,
  // });

  // / Reactively reads the stored double with the given `key`.
  // / If no boolean value is saved, the returned value will be `null`.
  // Stream<double?> streamDouble(String key);

  // / Saves the [String] `value` in memory with the assigned `key`.
  // / Use `ttl` to determine how long should the `value` remain in memory.
  // / If `ttl` is `null`, the `value` will permanently be
  // / stored in the device memory with the assigned `key`.
  // Future<void> setString(
  //   String key,
  //   String? value, {
  //   Duration? ttl,
  // });

  // / Reactively reads the stored String with the given `key`.
  // / If no boolean value is saved, the returned value will be `null`.
  // Stream<String?> streamString(String key);

  // / Saves the [int] `value` in memory with the assigned `key`.
  // / Use `ttl` to determine how long should the `value` remain in memory.
  // / If `ttl` is `null`, the `value` will permanently be
  // / stored in the device memory with the assigned `key`.
  // Future<void> setMap(
  //   String key,
  //   Map? value, {
  //   Duration? ttl,
  // });

  // / Reactively reads the stored Map<String,dynamic> with the given `key`.
  // / If no boolean value is saved, the returned value will be `null`.
  // Stream<Map<String, dynamic>?> streamMap(String key);

  // / Saves the [Map<String, dynamic>] `value` in memory with the assigned `key`.
  // / Use `ttl` to determine how long should the `value` remain in memory.
  // / If `ttl` is `null`, the `value` will permanently be
  // / stored in the device memory with the assigned `key`.
  // Future<String> setDoc(
  //   String collection,
  //   Map<String, dynamic> value, {
  //   String? docId,
  //   String docIdKey = 'id',
  //   Duration? ttl,
  // });

  // / Checks if the document with the assigned `docId` is available
  // / in the given `collection`
  // bool docExists(String collection, String docId);

  // / Checks if a speficis collection exists.
  // bool collectionExists(String collection);

  // Stream<Map<String, dynamic>?> streamDoc(String collection, String docId);

  // Future<Map<String, dynamic>?> fetchDoc(String collection, String docId);

  // Stream<List<Map<String, dynamic>>> streamDocs(String collection);
  // Future<List<Map<String, dynamic>>> fetchDocs(String collection);
  // Future<void> deleteDoc(String collection, String docId);

  // Stream<List<Map<String, dynamic>>> streamDocs(String collection);
  // Future<List<Map<String, dynamic>>> getDocs(String collection);
  // Future<void> deleteDoc(
  //   String collection,
  //   String docId, [
  //   String idKey = 'id',
  // ]);
  // Future<void> deleteKey(String key);

  /// Clears The Database
  Future<void> clear();

  Future<void> clearAllInstances();

  /// Closes all the open files and also the stream controller.
  /// This must be called when Kooza is no longer used by the app.
  /// The best ways to close Kooza are:
  /// - Instantiate Kooza in a StatefullWidget and close it using `dispose` method.
  /// - Instantiate Kooza in a bloc and close it using the `flutter_bloc`'s
  /// close method.
  /// - Provide it to the Widget tree using provider and closing it
  /// using the dispose property of Provider.
  Future<void> close();
}
