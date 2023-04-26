import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../domain/kooza_document.dart';

class KoozaSingleDocumentReference {
  final String boxName;
  final String documentName;

  const KoozaSingleDocumentReference({
    required this.boxName,
    required this.documentName,
  });

  /// Checks if the document exists.
  /// It does not delete the expired documents from Kooza.
  bool existsSync<T extends Object?>() {
    try {
      final box = Hive.box(boxName);

      // Check if it exists at all
      final existsInTheBox = box.containsKey(documentName);
      if (!existsInTheBox) return false;

      // Check if it is supposed to expire
      final data = box.get(documentName);
      var doc = KoozaDocument<T>.fromMap(data);

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
      if (kDebugMode) print('KOOZA_SINGLE_DOCUMENT_EXITS_SYNC: $e');
      return false;
    }
  }

  /// Checks if the document of type `T` exists in Kooza.
  /// If the document exists and is expired,
  /// it asynchronouly deletes it.
  Future<bool> exists<T extends Object?>() async {
    try {
      final box = Hive.box(boxName);

      // Check if it exists at all
      final existsInTheBox = box.containsKey(documentName);
      if (!existsInTheBox) return false;

      // Check if it is supposed to expire
      final data = box.get(documentName);
      var doc = KoozaDocument<T>.fromMap(data);

      // if there is no data in the document, then it does not exist.
      if (doc.data == null) return false;

      // if the data in the the document exists but there is no
      // expiration then it exists
      if (doc.ttl == null) return true;

      // Check if the document is expired
      final storedDuration = DateTime.now().difference(doc.creationDate);
      if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
        await box.delete(documentName);
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('KOOZA_SINGLE_DOCUMENT_EXITS: $e');
      return false;
    }
  }

  /// Saves the `data` with the type T in the store.
  /// T can only be built-in Dart types.
  /// `ttl` (time to live) is the amount of time the data will be
  /// stored in Kooza. By default `ttl` is set to 2 hours.
  Future<void> set<T extends Object?>(T data,
      {Duration ttl = const Duration(hours: 2)}) async {
    try {
      final box = Hive.box(boxName);
      var newDocument = KoozaDocument<T>.init(
        id: documentName,
        data: data,
        ttl: ttl,
        creationDate: DateTime.now(),
      );
      await box.put(documentName, newDocument.toMap());
    } catch (e) {
      if (kDebugMode) print('KOOZA_SET_SINGLE_DOCUMENT: $e');
    }
  }

  /// gets the latest stored value of the document.
  /// If the `ttl` is expired, the returned document will
  /// be `null` and its id will be an empty string
  Future<KoozaDocument<T>> get<T extends Object?>() async {
    try {
      final box = Hive.box(boxName);

      final data = await box.get(documentName);
      var doc = KoozaDocument<T>.fromMap(data);
      if (doc.ttl == null) return doc;

      final storedDuration = DateTime.now().difference(doc.creationDate);
      if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
        await box.delete(documentName);
        return KoozaDocument<T>.init();
      }

      return doc;
    } catch (e) {
      if (kDebugMode) print('KOOZA_GET_SINGLE_DOCUMENT: $e');
      return KoozaDocument<T>.init();
    }
  }

  /// Notifies updates of the current document in Kooza.
  /// An initial event is immediately sent,
  /// and further events will be sent whenever the document is modified.
  Stream<KoozaDocument<T>> snapshots<T extends Object?>() async* {
    try {
      final box = Hive.box(boxName);

      var initDoc = KoozaDocument<T>.fromMap(box.get(documentName));
      if (initDoc.ttl != null) {
        final storedDuration = DateTime.now().difference(initDoc.creationDate);
        if (storedDuration.inMilliseconds >= initDoc.ttl!.inMilliseconds) {
          await box.delete(documentName);
          initDoc = KoozaDocument<T>.init();
        }
      }

      yield* box
          .watch(key: documentName)
          .asyncMap((event) async {
            final newDoc = KoozaDocument<T>.fromMap(event.value);
            if (newDoc.ttl == null) return newDoc;

            final storedDuration =
                DateTime.now().difference(newDoc.creationDate);
            if (storedDuration.inMilliseconds >= newDoc.ttl!.inMilliseconds) {
              await box.delete(documentName);
              return KoozaDocument<T>.init();
            }
            return newDoc;
          })
          .startWith(initDoc)
          .handleError((e) {
            if (kDebugMode) print('KOOZA_SNAPSHOTS_SINGLE_DOCUMENT: $e');
          });
    } catch (e) {
      if (kDebugMode) print('KOOZA_SNAPSHOTS_SINGLE_DOCUMENT: $e');
    }
  }

  /// Deletes the current document from Kooza.
  Future<void> delete() async {
    try {
      final box = Hive.box(boxName);
      await box.delete(documentName);
    } catch (e) {
      if (kDebugMode) print('KOOZA_DELTE_SINGLE_DOCUMENT: $e');
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
}
