import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../kooza_base.dart';
import 'kooza_collection_reference_dep.dart';
import 'kooza_single_document_reference.dart';

class KoozaImpl extends Kooza {
  final Random _random;
  final String _dbName;
  final BehaviorSubject<Map<String, Map<String, dynamic>>> reference;
  // KoozaSingleDocumentReference? _singeDocRef;
  KoozaCollectionReference<Map<String, dynamic>>? _collectionRef;

  KoozaImpl._({
    required this.reference,
    required Random random,
    required String dbName,
  })  : _random = random,
        _dbName = dbName;

  factory KoozaImpl.init(String dbName) {
    final random = Random(DateTime.now().microsecond);
    final ref = BehaviorSubject<Map<String, Map<String, dynamic>>>.seeded({});
    return KoozaImpl._(random: random, dbName: dbName, reference: ref);
  }

  @override
  KoozaSingleDocumentReference singleDoc(String key) {
    return KoozaSingleDocumentReference(dbName: _dbName, documentName: key);
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
      // await _singeDocRef?.close();
      await _collectionRef?.close();
    } catch (e) {
      if (kDebugMode) print('Closing Kooza Error: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await Hive.deleteBoxFromDisk(_dbName);
      await Hive.deleteBoxFromDisk('${_dbName}single');
    } catch (e) {
      throw KoozaError(
        code: 'KOOZA_DELETE_DB',
        message: 'could not create $_dbName from Kooza',
      );
    }
  }

  @override
  Future<void> clearAllInstances() async {
    try {
      await Hive.deleteFromDisk();
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_DELETE_ALL_DB',
        message: 'could not delete all the dbs from Kooza',
      );
    }
  }
}
