import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../domain/kooza_document.dart';
import '../domain/kooza_query_snapshot.dart';

class KoozaDocumentReference<T extends Object?> {
  final String boxName;
  final String collectionName;
  final String documentId;

  KoozaDocumentReference({
    required this.boxName,
    required this.collectionName,
    required this.documentId,
  });

  /// Checks if the document exists.
  /// It does not delete the expired documents from Kooza.
  bool existsSync() {
    try {
      final box = Hive.box(boxName);

      // Check if it exists at all
      final collectionExists = box.containsKey(collectionName);
      if (!collectionExists) return false;

      final data = box.get(collectionName);
      final newCollection = KoozaQuerySnapshot<T>.fromMap(data);
      if (!newCollection.docExists(documentId)) return false;

      final doc = newCollection.getDoc(documentId);
      // if there is no data in the document, then it does not exist.
      if (doc.data == null) return false;

      // if the data in the the document exists but there is no
      // expiration then it exists
      if (doc.ttl == null) return true;

      // Check if the document is expired
      final storedDuration = DateTime.now().difference(doc.creationDate);
      if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('KOOZA_DOCUMENT_EXITS_SYNC: $e');
      return false;
    }
  }

  /// Checks if the document of type `T` exists in Kooza.
  /// If the document exists and is expired,
  /// it asynchronouly deletes it.
  Future<bool> exists() async {
    try {
      final box = Hive.box(boxName);

      // Check if it exists at all
      final collectionExists = box.containsKey(collectionName);
      if (!collectionExists) return false;

      final data = box.get(collectionName);
      var newCollection = KoozaQuerySnapshot<T>.fromMap(data);
      if (!newCollection.docExists(documentId)) return false;

      final doc = newCollection.getDoc(documentId);
      // if there is no data in the document, then it does not exist.
      if (doc.data == null) return false;

      // if the data in the the document exists but there is no
      // expiration then it exists
      if (doc.ttl == null) return true;

      // Check if the document is expired
      final storedDuration = DateTime.now().difference(doc.creationDate);
      if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
        newCollection = newCollection.delete(documentId);
        await box.put(collectionName, newCollection.toMap());
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('KOOZA_DOCUMENT_EXITS_SYNC: $e');
      return false;
    }
  }

  /// Saves the `data` with the type T in Kooza at
  /// the given collection path and document id.
  /// T can only be built-in Dart types.
  /// `ttl` (time to live) is the amount of time the data will be
  /// stored in Kooza. By default `ttl` is set to 2 hours.
  Future<void> set(T data, {Duration ttl = const Duration(hours: 2)}) async {
    try {
      final box = Hive.box(boxName);

      var newDoc = KoozaDocument<T>.init(
        id: documentId,
        data: data,
        ttl: ttl,
        creationDate: DateTime.now(),
      );

      if (!existsSync()) {
        var newCollection = KoozaQuerySnapshot.init();
        newCollection = newCollection.add(documentId, newDoc);
        await box.put(collectionName, newCollection.toMap());
        return;
      }

      final rawCollection = box.get(collectionName);
      var fetchedCollection = KoozaQuerySnapshot<T>.fromMap(rawCollection);
      fetchedCollection = fetchedCollection.add(documentId, newDoc);
      await box.put(collectionName, fetchedCollection.toMap());
    } catch (e) {
      if (kDebugMode) print('KOOZA_SET_DOCUMENT: $e');
    }
  }

  /// Asynchronously gets the document
  Future<KoozaDocument<T>> get() async {
    try {
      final docExists = await exists();
      if (!docExists) return KoozaDocument<T>.init();

      final box = Hive.box(boxName);
      final rawCollection = box.get(collectionName);
      var newCollection = KoozaQuerySnapshot<T>.fromMap(rawCollection);

      return newCollection.getDoc(documentId);
    } catch (e) {
      if (kDebugMode) print('KOOZA_GET_DOCUMENT: $e');
      return KoozaDocument<T>.init();
    }
  }

  /// Broadcasts a stream of data.
  Stream<KoozaDocument<T>> snapshots() async* {
    try {
      final docExists = await exists();
      if (docExists) {
        final box = Hive.box(boxName);

        final rawCollection = box.get(collectionName);
        var newCollection = KoozaQuerySnapshot<T>.fromMap(rawCollection);
        yield* box
            .watch(key: collectionName)
            .map((e) => KoozaQuerySnapshot<T>.fromMap(e.value))
            .startWith(newCollection)
            .map((e) => e.getDoc(documentId))
            .handleError((e) {
          if (kDebugMode) print("KOOZA_STREAM_DOCUMENT: $e");
        });
      }
    } catch (e) {
      if (kDebugMode) print("KOOZA_STREAM_DOCUMENT: $e");
    }
  }

  Future<void> delete() async {
    try {
      final docExists = await exists();
      if (!docExists) return;

      final box = Hive.box(boxName);

      final data = box.get(collectionName);
      var newCollection = KoozaQuerySnapshot<T>.fromMap(data);
      newCollection = newCollection.delete(documentId);

      await box.put(collectionName, newCollection.toMap());
    } catch (e) {
      if (kDebugMode) print("KOOZA_DELETE_DOCUMENT: $e");
    }
  }
}
