import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show kDebugMode;

import '../kooza_base.dart';
import 'kooza_collection_reference.dart';
import 'kooza_single_document_reference.dart';

class KoozaImpl extends Kooza {
  final Random _random;
  final String _dbName;
  KoozaSingleDocumentReference? _singeDocRef;
  KoozaCollectionReference<Map<String, dynamic>>? _collectionRef;
  KoozaImpl._({
    required Random random,
    required String dbName,
  })  : _random = random,
        _dbName = dbName;

  factory KoozaImpl.init(String dbName) {
    final random = Random(DateTime.now().microsecond);
    return KoozaImpl._(random: random, dbName: dbName);
  }

  @override
  KoozaSingleDocumentReference singleDoc(String key) {
    _singeDocRef ??= KoozaSingleDocumentReference.init(_dbName, key);
    _singeDocRef = _singeDocRef!.copyWith(documentName: key);
    return _singeDocRef!;
  }

  @override
  KoozaCollectionReference<Map<String, dynamic>> collection(
    String collectionName,
  ) {
    _collectionRef ??= KoozaCollectionReference<Map<String, dynamic>>.init(
      random: _random,
      dbName: _dbName,
      collectionName: collectionName,
    );
    _collectionRef = _collectionRef!.copyWith(
      random: _random,
      collectionName: collectionName,
    );
    return _collectionRef!;
  }

  @override
  Future<void> close() async {
    try {
      await _singeDocRef?.close();
      await _collectionRef?.close();
    } catch (e) {
      if (kDebugMode) print('Closing Kooza Error: $e');
    }
  }
}
