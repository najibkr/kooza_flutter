import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../kooza_base.dart';
import 'kooza_collection_reference.dart';
import 'kooza_single_document_reference.dart';

class KoozaImpl extends Kooza {
  final String _singleDocsBoxName;
  final String _collectionsBoxName;
  final Random _random;
  const KoozaImpl._({
    required String singleDocsBoxName,
    required String collectionsBoxName,
    required Random random,
  })  : _singleDocsBoxName = singleDocsBoxName,
        _collectionsBoxName = collectionsBoxName,
        _random = random;

  static KoozaImpl? _uniqueInstance;

  static Future<KoozaImpl> getInstance(String dbName, Random random) async {
    final singleDocsBoxName = '${dbName}_single_docs';
    final collectionsBoxName = '${dbName}_collections';

    try {
      await Hive.initFlutter('kooza');

      await Hive.openBox(singleDocsBoxName);

      await Hive.openBox(collectionsBoxName);

      _uniqueInstance ??= KoozaImpl._(
        singleDocsBoxName: singleDocsBoxName,
        collectionsBoxName: collectionsBoxName,
        random: random,
      );
      return _uniqueInstance!;
    } catch (e) {
      if (kDebugMode) print("KOOZA_GET_UNIQUE_INSTANCE: $e");

      _uniqueInstance ??= KoozaImpl._(
        singleDocsBoxName: singleDocsBoxName,
        collectionsBoxName: collectionsBoxName,
        random: random,
      );
      return _uniqueInstance!;
    }
  }

  @override
  KoozaSingleDocumentReference singleDoc(String documentName) {
    return KoozaSingleDocumentReference(
      boxName: _singleDocsBoxName,
      documentName: documentName,
    );
  }

  @override
  KoozaCollectionReference<Map<String, dynamic>> collection(
    String collectionName,
  ) {
    return KoozaCollectionReference<Map<String, dynamic>>(
      boxName: _collectionsBoxName,
      collectionName: collectionName,
      random: _random,
    );
  }

  /// Closes the Kooza's openned collections and single documents
  /// This helps free up memory when Kooza is not in use.
  @override
  Future<void> close() async {
    try {
      await Hive.close();
    } catch (e) {
      if (kDebugMode) print('KOOZA_CLOSE_DB: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      final singleDocsBox = Hive.box(_singleDocsBoxName);
      await singleDocsBox.clear();

      final collectionsBox = Hive.box(_collectionsBoxName);
      await collectionsBox.clear();
    } catch (e) {
      if (kDebugMode) print('KOOZA_CLEAR_BOXES: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final singleDocsBox = Hive.box(_singleDocsBoxName);
      await singleDocsBox.clear();

      final collectionsBox = Hive.box(_collectionsBoxName);
      await collectionsBox.clear();
    } catch (e) {
      if (kDebugMode) print('KOOZA_CLEAR_ALL_BOXES: $e');
    }
  }
}
