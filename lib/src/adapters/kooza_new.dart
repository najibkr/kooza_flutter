import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'kooza_collection_reference.dart';
import 'kooza_single_document_reference.dart';

class KoozaNew {
  final String dbName;
  final Random _random;
  const KoozaNew({required this.dbName, required Random random}) : _random = random;

  KoozaSingleDocumentReference singleDoc(String documentName) {
    return KoozaSingleDocumentReference(
      dbName: '${dbName}single',
      documentName: documentName,
    );
  }

  KoozaCollectionReference collection(String collectionName) {
    return KoozaCollectionReference(
      dbName: dbName,
      collectionName: collectionName,
      random: _random,
    );
  }

  Future<void> close() async {
    try {
      await Hive.box(dbName).close();
      await Hive.box('${dbName}single').close();
    } catch (e) {
      if (kDebugMode) print('KOOZA_CLOSE_DB: $dbName & ${dbName}single: $e');
    }
  }

  Future<void> clear() async {
    try {
      await Hive.deleteBoxFromDisk(dbName);
      await Hive.deleteBoxFromDisk('${dbName}single');
    } catch (e) {
      if (kDebugMode) print('KOOZA_CLEAR_DB: $dbName & ${dbName}single: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await Hive.deleteFromDisk();
    } catch (e) {
      if (kDebugMode) print('KOOZA_CLEAR_DB: $dbName & ${dbName}single: $e');
    }
  }
}
