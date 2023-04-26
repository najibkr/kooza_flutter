import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

import '../domain/kooza_document.dart';
import '../domain/kooza_query_snapshot.dart';
import 'kooza_document_reference.dart';

class KoozaCollectionReference<T extends Object?> {
  final String boxName;
  final String collectionName;
  final Random _random;

  const KoozaCollectionReference({
    required this.boxName,
    required this.collectionName,
    required Random random,
  }) : _random = random;

  KoozaDocumentReference doc(String documentId) {
    return KoozaDocumentReference(
      boxName: boxName,
      collectionName: collectionName,
      documentId: documentId,
    );
  }

  /// Checks if the collection exists.
  /// If the collection is empty, the returned value is `false`
  bool existsSync() {
    try {
      final box = Hive.box(boxName);

      // Check if it exists at all
      final collectionExists = box.containsKey(collectionName);
      if (!collectionExists) return false;

      final data = box.get(collectionName);
      final newCollection = KoozaQuerySnapshot<T>.fromMap(data);
      if (newCollection.isEmpty()) return false;

      return true;
    } catch (e) {
      if (kDebugMode) print('KOOZA_COLLECTION_EXITS_SYNC: $e');
      return false;
    }
  }

  /// Checks if the collection exists.
  /// If the collection is empty, the returned value is `false`
  bool exists() {
    try {
      final box = Hive.box(boxName);

      // Check if it exists at all
      final collectionExists = box.containsKey(collectionName);
      if (!collectionExists) return false;

      final data = box.get(collectionName);
      final newCollection = KoozaQuerySnapshot<T>.fromMap(data);
      if (newCollection.isEmpty()) return false;

      return true;
    } catch (e) {
      if (kDebugMode) print('KOOZA_COLLECTION_EXITS: $e');
      return false;
    }
  }

  /// Adds a new document to the collection
  /// and gives a random ID if `docId` is not provided
  Future<String?> add(
    T data, {
    String? docId,
    Duration ttl = const Duration(hours: 2),
  }) async {
    try {
      final newId = docId ?? _generateId();
      final box = Hive.box(boxName);

      var newDocument = KoozaDocument<T>.init(
        id: newId,
        data: data,
        ttl: ttl,
        creationDate: DateTime.now(),
      );

      if (exists()) {
        final rawData = box.get(collectionName);
        var newCollection = KoozaQuerySnapshot<T>.fromMap(rawData);
        newCollection = newCollection.add(newId, newDocument);
        await box.put(collectionName, newCollection.toMap());
        return newId;
      }

      var newCollection = KoozaQuerySnapshot<T>.init();
      newCollection = newCollection.add(newId, newDocument);
      await box.put(collectionName, newCollection.toMap());

      return newId;
    } catch (e) {
      if (kDebugMode) print('KOOZA_SET_DOCUMENT: $e');
      return null;
    }
  }

  Future<KoozaQuerySnapshot<T>> get() async {
    try {
      final box = Hive.box(boxName);
      final rawCollection = box.get(collectionName);
      return KoozaQuerySnapshot<T>.fromMap(rawCollection);
    } catch (e) {
      if (kDebugMode) print('KOOZA_GET_COLLECTION: $e');
      return KoozaQuerySnapshot<T>.init();
    }
  }

  /// Streams the collection by returning a [KoozaQuerySnapshot]
  Stream<KoozaQuerySnapshot<T>> snapshots() {
    try {
      final box = Hive.box(boxName);

      final rawCollection = box.get(collectionName);
      var newCollection = KoozaQuerySnapshot<T>.fromMap(rawCollection);

      return box
          .watch(key: collectionName)
          .map((e) => KoozaQuerySnapshot<T>.fromMap(e.value))
          .startWith(newCollection)
          .handleError((e) {
        if (kDebugMode) print("KOOZA_STREAM_DOCUMENT: $e");
      });
    } catch (e) {
      if (kDebugMode) print('KOOZA_STREAM_COLLECTION: $e');
      return Stream.value(KoozaQuerySnapshot<T>.init()).asBroadcastStream();
    }
  }

  Future<void> delete() async {
    try {
      final collectionExists = exists();
      if (!collectionExists) return;

      final box = Hive.box(boxName);
      await box.delete(collectionName);
    } catch (e) {
      if (kDebugMode) print('KOOZA_DELETE_COLLECTION: $e');
    }
  }

  Future<void> close() async {
    try {
      final box = Hive.box(boxName);
      await box.close();
    } catch (e) {
      if (kDebugMode) print("KOOZA_CLOSE_COLLECTION: $e");
    }
  }

  String _generateId() {
    final id = _random.nextInt(100000000);
    return 'KOOZA${id + 100000000}';
  }
}
