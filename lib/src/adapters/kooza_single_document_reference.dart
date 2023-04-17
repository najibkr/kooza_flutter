import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../domain/kooza_document.dart';

class KoozaSingleDocumentReference {
  final String dbName;
  final String documentName;

  const KoozaSingleDocumentReference({
    required this.dbName,
    required this.documentName,
  });

  /// Checks if the document exists in Kooza
  Future<bool> exists<T>() async {
    try {
      final box = await Hive.openLazyBox(dbName);
      final exists = box.containsKey(documentName);
      if (!exists) return false;

      final data = await box.get(documentName);
      var doc = KoozaDocument<T>.fromMap(data);
      if (doc.ttl == null) return true;

      final storedDuration = DateTime.now().difference(doc.creationDate);
      if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
        await box.delete(documentName);
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('KOOZA_DOCUMENT_EXITS: $e');
      return false;
    }
  }

  /// Saves the `data` with the type T in the store.
  /// T can only be built-in Dart types.
  /// `ttl` (time to live) is the amount of time the data will be
  /// stored in Kooza. By default `ttl` is set to 2 hours.
  Future<void> set<T extends Object?>(T data, {Duration ttl = const Duration(hours: 2)}) async {
    try {
      final box = await Hive.openLazyBox(dbName);
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
      final box = await Hive.openLazyBox(dbName);

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
      final box = await Hive.openLazyBox(dbName);

      if (box.containsKey(documentName)) {
        final data = await box.get(documentName);
        var doc = KoozaDocument<T>.fromMap(data);
        if (doc.ttl != null) {
          final storedDuration = DateTime.now().difference(doc.creationDate);
          if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
            await box.delete(documentName);
          }
        }
      }
      final doc = KoozaDocument<T>.fromMap(await box.get(documentName));
      yield* box
          .watch(key: documentName)
          .asyncMap((event) async {
            try {
              if (box.containsKey(documentName)) {
                final data = await box.get(documentName);
                var doc = KoozaDocument<T>.fromMap(data);
                if (doc.ttl != null) {
                  final storedDuration = DateTime.now().difference(doc.creationDate);
                  if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
                    await box.delete(documentName);
                  }
                }
              }
              return KoozaDocument<T>.fromMap(event.value);
            } catch (e) {
              if (kDebugMode) print('KOOZA_SNAPSHOTS_SINGLE_DOCUMENT: $e');
              return KoozaDocument<T>.init();
            }
          })
          .startWith(doc)
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
      final box = await Hive.openLazyBox(dbName);
      await box.delete(documentName);
    } catch (e) {
      if (kDebugMode) print('KOOZA_DELTE_SINGLE_DOCUMENT: $e');
    }
  }
}
