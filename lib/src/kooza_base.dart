import 'package:hive_flutter/hive_flutter.dart';

import 'adapters/kooza_impl.dart';

export 'domain/kooza_document.dart';
export 'domain/kooza_error.dart';

abstract class Kooza {
  static Future<Kooza> getInstance(
    String dbName, {
    String storageDirectory = 'kooza',
  }) async {
    await Hive.initFlutter(storageDirectory);
    return KoozaImpl.getInstance(dbName);
  }

  /// Saves the [bool] `value` in memory with the assigned `key`.
  /// Use `ttl` to determine how long should the `value` remain in memory.
  /// If no `ttl` is `null`, the `value` will permanently be
  /// stored in the device memory with the assigned `key`.
  Future<void> setBool(
    String key,
    bool? value, {
    Duration? ttl,
  });

  /// Reactively reads the stored boolean with the given `key`.
  /// If no boolean value is saved, the returned value will be `null`.
  Stream<bool?> streamBool(String key);

  /// Asynchronously reads the stored boolean with the given `key`.
  /// If no boolean value is saved, the returned value will be `null`.
  Future<bool?> fetchBool(String key);

  /// Saves the [int] `value` in memory with the assigned `key`.
  /// Use `ttl` to determine how long should the `value` remain in memory.
  /// If `ttl` is `null`, the `value` will permanently be
  /// stored in the device memory with the assigned `key`.
  Future<void> setInt(
    String key,
    int? value, {
    Duration? ttl,
  });

  /// Reactively reads the stored int with the given `key`.
  /// If no boolean value is saved, the returned value will be `null`.
  Stream<int?> streamInt(String key);

  /// Saves the [double] `value` in memory with the assigned `key`.
  /// Use `ttl` to determine how long should the `value` remain in memory.
  /// If `ttl` is `null`, the `value` will permanently be
  /// stored in the device memory with the assigned `key`.
  Future<void> setDouble(
    String key,
    double? value, {
    Duration? ttl,
  });

  /// Reactively reads the stored double with the given `key`.
  /// If no boolean value is saved, the returned value will be `null`.
  Stream<double?> streamDouble(String key);

  /// Saves the [String] `value` in memory with the assigned `key`.
  /// Use `ttl` to determine how long should the `value` remain in memory.
  /// If `ttl` is `null`, the `value` will permanently be
  /// stored in the device memory with the assigned `key`.
  Future<void> setString(
    String key,
    String? value, {
    Duration? ttl,
  });

  /// Reactively reads the stored String with the given `key`.
  /// If no boolean value is saved, the returned value will be `null`.
  Stream<String?> streamString(String key);

  /// Saves the [int] `value` in memory with the assigned `key`.
  /// Use `ttl` to determine how long should the `value` remain in memory.
  /// If `ttl` is `null`, the `value` will permanently be
  /// stored in the device memory with the assigned `key`.
  Future<void> setMap(
    String key,
    Map? value, {
    Duration? ttl,
  });

  /// Reactively reads the stored Map<String,dynamic> with the given `key`.
  /// If no boolean value is saved, the returned value will be `null`.
  Stream<Map<String, dynamic>?> streamMap(String key);

  /// Saves the [Map<String, dynamic>] `value` in memory with the assigned `key`.
  /// Use `ttl` to determine how long should the `value` remain in memory.
  /// If `ttl` is `null`, the `value` will permanently be
  /// stored in the device memory with the assigned `key`.
  Future<String> setDoc(
    String collection,
    Map<String, dynamic> value, {
    String? docId,
    Duration? ttl,
  });

  Stream<List<Map<String, dynamic>>> streamDocs(String collection);

  // Stream<Map<String, dynamic>?> streamDoc(
  //   String collection,
  //   String docId, [
  //   String idKey = 'id',
  // ]);

  // // Future<void> cacheBool(String key, bool value);
  // Stream<bool?> streamBool(String key);
  // Future<bool?> getBool(String key);

  // Future<void> cacheInt(String key, int value);
  // Stream<int?> streamInt(String key);
  // Future<int?> getInt(String key);

  // Future<void> cacheDouble(String key, double value);
  // Stream<double?> streamDouble(String key);
  // Future<double?> getDouble(String key);

  // Future<void> cacheString(String key, String? value);
  // Stream<String?> streamString(String key);
  // Future<String?> getString(String key);
  // Future<void> cacheMap(String key, Map<String, dynamic> value);
  // Stream<Map<String, dynamic>?> streamMap(String key);
  // Future<Map<String, dynamic>?> getMap(String key);

  // Future<void> cacheDoc(
  //   String collection,
  //   Map<String, dynamic> doc, [
  //   String idKey = 'id',
  // ]);

  // Stream<Map<String, dynamic>?> streamDoc(
  //   String collection,
  //   String docId, [
  //   String idKey = 'id',
  // ]);
  // Future<Map<String, dynamic>?> getDoc(
  //   String collection,
  //   String docId, [
  //   String idKey = 'id',
  // ]);
  // Stream<List<Map<String, dynamic>>> streamDocs(String collection);
  // Future<List<Map<String, dynamic>>> getDocs(String collection);
  // Future<void> deleteDoc(
  //   String collection,
  //   String docId, [
  //   String idKey = 'id',
  // ]);
  // Future<void> deleteCollection(String collection);

  Future<void> close();
}
