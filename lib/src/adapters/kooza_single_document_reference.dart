import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/subjects.dart';

import '../domain/kooza_document.dart';
import '../domain/kooza_error.dart';

class KoozaSingleDocumentReference {
  final String _dbName;
  final String _documentId;
  final BehaviorSubject<Map<String, KoozaDocument<dynamic>>> _docs;

  const KoozaSingleDocumentReference._({
    required String dbName,
    required String documentId,
    required BehaviorSubject<Map<String, KoozaDocument<dynamic>>> docs,
  })  : _dbName = dbName,
        _documentId = documentId,
        _docs = docs;

  factory KoozaSingleDocumentReference.init(String dbName, String name) {
    return KoozaSingleDocumentReference._(
      dbName: '${dbName}single',
      documentId: name,
      docs: BehaviorSubject<Map<String, KoozaDocument<dynamic>>>.seeded({}),
    );
  }

  KoozaSingleDocumentReference copyWith({
    String? dbName,
    String? documentName,
  }) {
    return KoozaSingleDocumentReference._(
      dbName: dbName != null ? '${dbName}single' : _dbName,
      documentId: documentName ?? _documentId,
      docs: _docs,
    );
  }

  /// Saves the new document with the type T in the store.
  /// T can only be built-in Dart types.
  Future<void> set<T extends Object?>(T data, {Duration? ttl}) async {
    try {
      var newDocument = KoozaDocument<T>.init(
        id: _documentId,
        data: data,
        ttl: ttl,
        creationDate: DateTime.now(),
      );

      final newBox = await _getCurrentBox();
      await newBox.put(_documentId, newDocument.toMap());

      var newDocuments = Map<String, KoozaDocument<dynamic>>.from(_docs.value);
      newDocuments[_documentId] = newDocument;
      _docs.sink.add(newDocuments);
    } on KoozaError {
      rethrow;
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_SET_SINGLE_DOCUMENT',
        message: 'The document could not be saved in Kooza',
      );
    }
  }

  Future<KoozaDocument<T>> get<T extends Object?>() async {
    try {
      final newBox = await _getCurrentBox();
      final docExists = _docs.value.containsKey(_documentId);
      if (!docExists) await _sinkCachedData(newBox);

      var doc = KoozaDocument<T>.fromDynamicData(_docs.value[_documentId]);
      doc = await _removeExpiredDoc<T>(doc);

      return doc;
    } on KoozaError {
      rethrow;
    } catch (e) {
      throw KoozaError(
        code: 'KOOZA_GET_SINGLE_DOCUMENT',
        message: 'Kooza failed to get the document named $_documentId',
      );
    }
  }

  Stream<KoozaDocument<T>> snapshots<T extends Object?>() async* {
    try {
      final newBox = await _getCurrentBox();
      final docExists = _docs.value.containsKey(_documentId);
      if (!docExists) await _sinkCachedData(newBox);

      var doc = KoozaDocument<T>.fromDynamicData(_docs.value[_documentId]);
      await _removeExpiredDoc<T>(doc);

      yield* _docs.stream.map((event) {
        return KoozaDocument<T>.fromDynamicData(event[_documentId]);
      });
    } on KoozaError {
      rethrow;
    } catch (e) {
      if (kDebugMode) print("KOOZA_GET_SINGLE_DOCUMENT: $_documentId $e");
      throw KoozaError(
        code: 'KOOZA_GET_SINGLE_DOCUMENT',
        message: 'Kooza failed to get the document named $_documentId',
      );
    }
  }

  Future<void> delete() async {
    try {
      final newBox = await _getCurrentBox();
      await newBox.delete(_documentId);
      var newDocuments = Map<String, KoozaDocument<dynamic>>.from(_docs.value);
      newDocuments.removeWhere((key, value) => key == _documentId);
      _docs.sink.add(newDocuments);
    } on KoozaError {
      rethrow;
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_SET_SINGLE_DOCUMENT',
        message: 'The document could not be saved in Kooza',
      );
    }
  }

  Future<Box> _getCurrentBox() async {
    try {
      final boxExists = await Hive.boxExists(_dbName);
      if (!boxExists) {
        final lazyBox = await Hive.openBox(_dbName);
        return lazyBox;
      } else if (!Hive.isBoxOpen(_dbName)) {
        final newBox = await Hive.openBox(_dbName);
        await _sinkCachedData(newBox);
        return newBox;
      } else {
        final box = Hive.box(_dbName);
        if (_docs.value.isEmpty) await _sinkCachedData(box);
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

  Future<void> _sinkCachedData(Box box) async {
    try {
      final docRaw = box.get(_documentId);
      final koozaDoc = KoozaDocument<dynamic>.fromMap(docRaw);
      var newDocuments = Map<String, KoozaDocument<dynamic>>.from(_docs.value);
      newDocuments[_documentId] = koozaDoc;
      _docs.sink.add(newDocuments);
    } on KoozaError {
      rethrow;
    } catch (e) {
      if (kDebugMode) print('_sinkCachedData: $e');
      throw const KoozaError(
        code: 'KOOZA_SINK_CACHED_SINGLE_DOCUMENTS',
        message: 'Kooza could not read data from your device memory',
      );
    }
  }

  Future<KoozaDocument<T>> _removeExpiredDoc<T extends Object?>(
    KoozaDocument<T> doc,
  ) async {
    try {
      if (doc.ttl == null) return doc;

      final storedDuration = DateTime.now().difference(doc.creationDate);
      if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
        var newDocs = Map<String, KoozaDocument<dynamic>>.from(_docs.value);
        newDocs[_documentId] = KoozaDocument<T>.init();
        _docs.sink.add(newDocs);
        final newBox = await _getCurrentBox();
        await newBox.delete(_documentId);
        return KoozaDocument<T>.init();
      }
      return doc;
    } on KoozaError {
      rethrow;
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_REMOVE_EXPIRED_VALUE',
        message: 'could not remove expired value from Kooza',
      );
    }
  }

  Future<void> close() async {
    final box = await _getCurrentBox();
    await box.close();
    await _docs.close();
  }
}
