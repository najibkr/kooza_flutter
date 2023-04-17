import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';

import '../domain/kooza_document.dart';

class KoozaDocumentReference<T extends Object?> {
  final String dbName;
  final String collectionName;
  final String documentId;

  KoozaDocumentReference({
    required this.dbName,
    required this.collectionName,
    required this.documentId,
  });

  /// Saves the `data` with the type T in Kooza at
  /// the given collection path and document id.
  /// T can only be built-in Dart types.
  /// `ttl` (time to live) is the amount of time the data will be
  /// stored in Kooza. By default `ttl` is set to 2 hours.
  Future<void> set(T data, {Duration ttl = const Duration(hours: 2)}) async {
    try {
      final _ = await Hive.openLazyBox(dbName);
      var __ = KoozaDocument<T>.init(
        id: documentId,
        data: data,
        ttl: ttl,
        creationDate: DateTime.now(),
      );

      // var colletion = Map<String, KoozaDocument<T>>.from(_docs.value);
      // colletion[_documentId] = newDocument;
      // _docs.sink.add(colletion);

      // var collectionMap = colletion.map((k, v) => MapEntry(k, v.toMap()));
      // await newBox.put(_collectionName, collectionMap);
    } catch (e) {
      if (kDebugMode) print('KOOZA_SET_DOCUMENT: $e');
    }
  }

  // /// Asynchronously gets the document
  // Future<KoozaDocument<T>> get() async {
  //   try {
  //     final newBox = await _getCurrentBox();
  //     var doc = KoozaDocument<T>.fromDynamicData(_docs.value[_documentId]);
  //     doc = await _removeExpiredDoc(newBox, doc);
  //     return doc;
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     throw KoozaError(
  //       code: 'KOOZA_GET_DOCUMENT',
  //       message: 'Kooza failed to get the document named $_documentId',
  //     );
  //   }
  // }

  // /// Broadcasts a stream of data.
  // Stream<KoozaDocument<T>> snapshots() async* {
  //   try {
  //     final newBox = await _getCurrentBox();

  //     var doc = KoozaDocument<T>.fromDynamicData(_docs.value[_documentId]);
  //     await _removeExpiredDoc(newBox, doc);

  //     yield* _docs.stream.map((event) {
  //       return KoozaDocument<T>.fromDynamicData(event[_documentId]);
  //     });
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     if (kDebugMode) print("KOOZA_GET_SINGLE_DOCUMENT: $_documentId $e");
  //     throw KoozaError(
  //       code: 'KOOZA_STREAM_DOCUMENT',
  //       message: 'Kooza failed to get the document named $_documentId',
  //     );
  //   }
  // }

  // Future<void> delete() async {
  //   try {
  //     final b = await _getCurrentBox();
  //     var docs = Map<String, KoozaDocument<T>>.from(_docs.value);
  //     docs.removeWhere((key, value) => key == _documentId);
  //     _docs.sink.add(docs);
  //     await b.put(_collectionName, docs.map((k, v) => MapEntry(k, v.toMap())));
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     throw const KoozaError(
  //       code: 'KOOZA_DELETE_DOCUMENT',
  //       message: 'The document could not be deleted from Kooza',
  //     );
  //   }
  // }

  // Future<bool> exists() async {
  //   try {
  //     await _getCurrentBox();
  //     var newDocuments = Map<String, KoozaDocument<T>>.from(_docs.value);
  //     return newDocuments.containsKey(_documentId);
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     throw const KoozaError(
  //       code: 'KOOZA_DOCUMENT_EXITS',
  //       message: 'The document could not be checked in Kooza',
  //     );
  //   }
  // }

  // Future<Box> _getCurrentBox() async {
  //   try {
  //     final boxExists = await Hive.boxExists(_dbName);
  //     if (!boxExists) {
  //       final lazyBox = await Hive.openBox(_dbName);
  //       return lazyBox;
  //     } else if (!Hive.isBoxOpen(_dbName)) {
  //       final newBox = await Hive.openBox(_dbName);
  //       _sinkCachedData(newBox);
  //       return newBox;
  //     } else {
  //       final box = Hive.box(_dbName);
  //       if (_docs.value.isEmpty) _sinkCachedData(box);
  //       return box;
  //     }
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     if (kDebugMode) print('KOOZA_GET_CURRENT_BOX: $e');
  //     throw const KoozaError(
  //       code: 'KOOZA_GET_CURRENT_BOX',
  //       message: 'Could not initialize a new Kooza database instance',
  //     );
  //   }
  // }

  // void _sinkCachedData(Box box) {
  //   try {
  //     final collectionRaw = box.get(_collectionName);
  //     if (collectionRaw == null) return;
  //     final collMap = Map<String, dynamic>.from(collectionRaw);

  //     final collection = collMap.map((k, v) {
  //       return MapEntry(k, KoozaDocument<T>.fromMap(v));
  //     });
  //     _docs.sink.add(collection);
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     if (kDebugMode) print('_sinkCachedData: $e');
  //     throw const KoozaError(
  //       code: 'KOOZA_SINK_CACHED_DOCUMENTS',
  //       message: 'Kooza could not read data from your device memory',
  //     );
  //   }
  // }

  // Future<KoozaDocument<T>> _removeExpiredDoc(
  //   Box box,
  //   KoozaDocument<T> doc,
  // ) async {
  //   try {
  //     if (doc.ttl == null) return doc;

  //     final duration = DateTime.now().difference(doc.creationDate);
  //     final isExpired = duration.inMilliseconds >= doc.ttl!.inMilliseconds;

  //     if (isExpired) {
  //       var collection = Map<String, KoozaDocument<T>>.from(_docs.value);
  //       collection.removeWhere((key, value) => key == _documentId);
  //       _docs.sink.add(collection);
  //       await box.delete(_documentId);
  //       return KoozaDocument<T>.init();
  //     }
  //     return doc;
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     throw const KoozaError(
  //       code: 'KOOZA_REMOVE_EXPIRED_VALUE',
  //       message: 'could not remove expired value from Kooza',
  //     );
  //   }
  // }

  // Future<void> close() async {
  //   await _docs.close();
  // }
}
