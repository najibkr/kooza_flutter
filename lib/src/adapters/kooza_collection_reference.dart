import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../domain/kooza_collection.dart';
import '../domain/kooza_error.dart';
import 'kooza_document_reference.dart';

class KoozaCollectionReference<T extends Object?> {
  final Random _random;
  final String _dbName;
  final String _collectionName;
  final BehaviorSubject<Map<String, KoozaCollection<T>>> _collections;
  KoozaDocumentReference<T>? _docRef;

  KoozaCollectionReference._({
    required Random random,
    required String dbName,
    required String collectionName,
    required BehaviorSubject<Map<String, KoozaCollection<T>>> collections,
  })  : _random = random,
        _dbName = dbName,
        _collectionName = collectionName,
        _collections = collections;

  factory KoozaCollectionReference.init({
    required Random random,
    required String dbName,
    required String collectionName,
  }) {
    return KoozaCollectionReference<T>._(
      random: random,
      dbName: dbName,
      collectionName: collectionName,
      collections: BehaviorSubject<Map<String, KoozaCollection<T>>>.seeded({}),
    );
  }

  KoozaCollectionReference<T> copyWith({
    Random? random,
    String? dbName,
    String? collectionName,
  }) {
    return KoozaCollectionReference<T>._(
      random: random ?? _random,
      dbName: dbName ?? _dbName,
      collectionName: collectionName ?? _collectionName,
      collections: _collections,
    );
  }

  KoozaDocumentReference<T> doc(String documentId) {
    _docRef ??= KoozaDocumentReference<T>.init(
      dbName: _dbName,
      collectionName: _collectionName,
      documentId: documentId,
    );

    _docRef = _docRef!.copyWith(
      dbName: _dbName,
      collectionName: _collectionName,
      documentId: documentId,
    );
    return _docRef!;
  }

  Stream<KoozaCollection<T>> snapshots() async* {
    try {
      await _getCurrentBox();
      yield* _collections.stream.map((event) {
        final data = event[_collectionName];
        return data ?? const KoozaCollection.init();
      }).handleError(
        (e) => throw const KoozaError(
          code: 'KOOZA_STREAM_COLLECTION',
          message: 'The collection could not be streamed from Kooza',
        ),
      );
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_STREAM_COLLECTION',
        message: 'The collection could not be streamed from Kooza',
      );
    }
  }

  Future<KoozaCollection<T>> get() async {
    try {
      await _getCurrentBox();
      final collection = _collections.value[_collectionName];
      return collection ?? const KoozaCollection.init();
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_GET_COLLECTION',
        message: 'The collection could not be fetched from Kooza',
      );
    }
  }

  Future<String> add(T data, {String? docID, Duration? ttl}) async {
    try {
      final newId = docID ?? _generateId();
      var collections =
          Map<String, KoozaCollection<T>>.from(_collections.value);
      var collection =
          collections[_collectionName] ?? KoozaCollection<T>.init();
      collection = collection.add(newId, data, ttl: ttl);
      collections[_collectionName] = collection;
      _collections.sink.add(collections);
      final box = await _getCurrentBox();
      await box.put(_collectionName, collection.toMap());
      return newId;
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_ADD_TO_COLLECTION',
        message: 'Could not add the new document to Kooza collection',
      );
    }
  }

  Future<void> delete() async {
    try {
      final newBox = await _getCurrentBox();
      var data = Map<String, KoozaCollection<T>>.from(_collections.value);
      data.removeWhere((key, value) => key == _collectionName);
      _collections.sink.add(data);
      await newBox.delete(_collectionName);
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_DELETE_COLLECTION',
        message: 'The collection could not be deleted from Kooza',
      );
    }
  }

  // /// Saves the new document with the type T in the store.
  // /// T can only be built-in Dart types.
  // Future<void> set(T data, {Duration? ttl}) async {
  //   try {
  //     var newDocument = KoozaDocument<T>.init(
  //       id: _documentName,
  //       data: data,
  //       ttl: ttl,
  //       creationDate: DateTime.now(),
  //     );

  //     final newBox = await _getCurrentBox();
  //     await newBox.put(_documentName, newDocument.toMap());

  //     var newDocuments = Map<String, KoozaDocument<T>>.from(_docs.value);
  //     newDocuments[_documentName] = newDocument;
  //     _docs.sink.add(newDocuments);
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     throw const KoozaError(
  //       code: 'KOOZA_SET_SINGLE_DOCUMENT',
  //       message: 'The document could not be saved in Kooza',
  //     );
  //   }
  // }

  // Future<KoozaDocument<Map<String, dynamic>>> get() async {
  //   try {
  //     final newBox = await _getCurrentBox();
  //     final docExists = _docs.value.containsKey(_documentName);
  //     if (!docExists) await _sinkCachedData(newBox);

  //     var doc = KoozaDocument<Map<String, dynamic>>.fromDynamicData(
  //         _docs.value[_documentName]);
  //     doc = await _removeExpiredDoc(doc);

  //     return doc;
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     throw KoozaError(
  //       code: 'KOOZA_GET_SINGLE_DOCUMENT',
  //       message: 'Kooza failed to get the document named $_documentName',
  //     );
  //   }
  // }

  // Stream<KoozaDocument<Map<String, dynamic>>> snapshot() async* {
  //   try {
  //     final newBox = await _getCurrentBox();
  //     final docExists = _docs.value.containsKey(_documentName);
  //     if (!docExists) await _sinkCachedData(newBox);

  //     var doc = KoozaDocument<Map<String, dynamic>>.fromDynamicData(
  //         _docs.value[_documentName]);
  //     await _removeExpiredDoc(doc);

  //     yield* _docs.stream.map((event) {
  //       return KoozaDocument<Map<String, dynamic>>.fromDynamicData(
  //           event[_documentName]);
  //     });
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     if (kDebugMode) print("KOOZA_GET_SINGLE_DOCUMENT: $_documentName $e");
  //     throw KoozaError(
  //       code: 'KOOZA_GET_SINGLE_DOCUMENT',
  //       message: 'Kooza failed to get the document named $_documentName',
  //     );
  //   }
  // }

  // Future<void> delete() async {
  //   try {
  //     final newBox = await _getCurrentBox();
  //     await newBox.delete(_documentName);
  //     var newDocuments =
  //         Map<String, KoozaDocument<Map<String, dynamic>>>.from(_docs.value);
  //     newDocuments.removeWhere((key, value) => key == _documentName);
  //     _docs.sink.add(newDocuments);
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     throw const KoozaError(
  //       code: 'KOOZA_SET_SINGLE_DOCUMENT',
  //       message: 'The document could not be saved in Kooza',
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
  //       await _sinkCachedData(newBox);
  //       return newBox;
  //     } else {
  //       return Hive.box(_dbName);
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

  // Future<void> _sinkCachedData(Box box) async {
  //   try {
  //     // final newBox = await _getCurrentBox();
  //     final docRaw = box.get(_documentName);
  //     final koozaDoc = KoozaDocument<Map<String, dynamic>>.fromMap(docRaw);
  //     var newDocuments =
  //         Map<String, KoozaDocument<Map<String, dynamic>>>.from(_docs.value);
  //     newDocuments[_documentName] = koozaDoc;
  //     _docs.sink.add(newDocuments);
  //   } on KoozaError {
  //     rethrow;
  //   } catch (e) {
  //     if (kDebugMode) print('_sinkCachedData: $e');
  //     throw const KoozaError(
  //       code: 'KOOZA_SINK_CACHED_SINGLE_DOCUMENTS',
  //       message: 'Kooza could not read data from your device memory',
  //     );
  //   }
  // }

  // Future<KoozaDocument<Map<String, dynamic>>> _removeExpiredDoc(
  //   KoozaDocument<Map<String, dynamic>> doc,
  // ) async {
  //   try {
  //     if (doc.ttl == null) return doc;

  //     final storedDuration = DateTime.now().difference(doc.creationDate);
  //     if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
  //       var newDocs =
  //           Map<String, KoozaDocument<Map<String, dynamic>>>.from(_docs.value);
  //       newDocs[_documentName] = KoozaDocument<Map<String, dynamic>>.init();
  //       _docs.sink.add(newDocs);
  //       final newBox = await _getCurrentBox();
  //       await newBox.delete(_documentName);
  //       return KoozaDocument<Map<String, dynamic>>.init();
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

  Future<Box> _getCurrentBox() async {
    try {
      final boxExists = await Hive.boxExists(_dbName);
      if (!boxExists) {
        final lazyBox = await Hive.openBox(_dbName);
        return lazyBox;
      } else if (!Hive.isBoxOpen(_dbName)) {
        final newBox = await Hive.openBox(_dbName);
        _sinkCachedData(newBox);
        return newBox;
      } else {
        final box = Hive.box(_dbName);
        if (_collections.value.isEmpty) _sinkCachedData(box);
        return box;
      }
    } on KoozaError {
      rethrow;
    } catch (e) {
      if (kDebugMode) print('KOOZA_GET_CURRENT_BOX: $e');
      throw const KoozaError(
        code: 'KOOZA_GET_CURRENT_BOX',
        message: 'Could not initialize a new Kooza database instance',
      );
    }
  }

  void _sinkCachedData(Box box) {
    try {
      var collections = Map<String, KoozaCollection<T>>.from({});
      for (var key in box.keys) {
        final collectionRaw = box.get(key);
        if (collectionRaw == null) return;
        collections[key] = KoozaCollection<T>.fromMap(collectionRaw);
      }
      _collections.sink.add(collections);
    } catch (e) {
      if (kDebugMode) print('_sinkCachedData: $e');
      throw const KoozaError(
        code: 'KOOZA_SINK_CACHED_COLLECTION',
        message: 'Kooza could not read collections from your device disk',
      );
    }
  }

  String _generateId() {
    final id = _random.nextInt(100000000);
    return 'KOOZA${id + 100000000}';
  }

  Future<void> close() async {
    await _docRef?.close();
  }
}
