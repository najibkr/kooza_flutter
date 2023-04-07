import 'dart:math';

import 'package:hive/hive.dart';
import 'package:rxdart/subjects.dart';

import '../domain/kooza_collection.dart';
import '../domain/kooza_value.dart';
import '../kooza_base.dart';

class KoozaImpl implements Kooza {
  final BehaviorSubject<Map<String, dynamic>> _subject;
  final Box _box;
  final Random _rand;
  const KoozaImpl._({
    required BehaviorSubject<Map<String, dynamic>> subject,
    required Box box,
    required Random rand,
  })  : _subject = subject,
        _box = box,
        _rand = rand;

  static KoozaImpl? _uniqueInstance;

  static Future<KoozaImpl> getInstance(String dbName) async {
    try {
      if (_uniqueInstance == null) {
        final box = await Hive.openBox(dbName);
        final subject = BehaviorSubject<Map<String, dynamic>>.seeded({});
        final rand = Random(DateTime.now().microsecondsSinceEpoch);
        _uniqueInstance = KoozaImpl._(subject: subject, box: box, rand: rand);
      }
      return _uniqueInstance!;
    } catch (e) {
      throw const KoozaError(
        code: 'KOOZA_GET_INSTANCE',
        message: 'Could not initialize a new Kooza instance',
      );
    }
  }

  @override
  Future<void> setBool(String key, bool? value, {Duration? ttl}) async {
    try {
      var doc = KoozaValue.init(
        value: value,
        ttl: ttl,
        timestamp: DateTime.now(),
      ).toMap();
      _subject.sink.add({key: doc});
      await _box.put(key, doc);
    } catch (e) {
      throw KoozaError(
        code: 'KOOZA_SET_BOOL',
        message: 'The boolean value ($value) could not be saved in Kooza',
      );
    }
  }

  @override
  Stream<bool?> streamBool(String key) {
    if (!_subject.value.containsKey(key)) {
      final result = _box.get(key);
      if (result != null) {
        var subjectData = Map<String, dynamic>.from(_subject.value);
        subjectData[key] = result;
        _subject.sink.add(subjectData);
      }
    }
    return _subject.stream.asyncMap((event) async {
      final data = event[key];
      if (data == null) return data;

      final doc = KoozaValue.fromMap(Map<String, dynamic>.from(data));
      if (doc.ttl == null) return doc.value;

      final storedDuration = DateTime.now().difference(doc.timestamp);
      if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
        var subjectData = Map<String, dynamic>.from(_subject.value);
        subjectData.remove(key);
        _subject.sink.add(subjectData);
        await _box.delete(key);
        return null;
      }

      return doc.value;
    });
  }

  @override
  Future<bool?> fetchBool(String key) async {
    try {
      if (_subject.value[key] == null) {
        final result = _box.get(key);
        if (result == null) return null;
        var subjectData = Map<String, dynamic>.from(_subject.value);
        subjectData[key] = result;
        _subject.sink.add(subjectData);
      }

      final data = _subject.value[key];
      if (data == null) return data;
      final doc = KoozaValue.fromMap(Map<String, dynamic>.from(data));
      if (doc.ttl == null) return doc.value;

      final storedDuration = DateTime.now().difference(doc.timestamp);
      if (storedDuration.inMilliseconds >= doc.ttl!.inMilliseconds) {
        var subjectData = Map<String, dynamic>.from(_subject.value);
        subjectData.remove(key);
        _subject.sink.add(subjectData);
        await _box.delete(key);
        return null;
      }
      return doc.value;
    } catch (e) {
      throw KoozaError(
        code: 'KOOZA_FETCH_BOOL',
        message: 'Could not get the boolean value with the key $key',
      );
    }
  }

  @override
  Future<void> setInt(String key, int? value, {Duration? ttl}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setDouble(String key, double? value, {Duration? ttl}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setString(String key, String? value, {Duration? ttl}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setMap(String key, Map? value, {Duration? ttl}) {
    throw UnimplementedError();
  }

  @override
  Future<String> setDoc(
    String collection,
    Map<String, dynamic> value, {
    String? docId,
    Duration? ttl,
  }) async {
    try {
      final newId = docId ?? _generateId();
      if (!_subject.value.containsKey(collection)) {
        final result = _box.get(collection);
        if (result != null) {
          var subjectData = Map<String, dynamic>.from(_subject.value);
          subjectData[collection] = result;
          _subject.sink.add(subjectData);
        }
      }

      var collRef = KoozaCollection.fromMap(_subject.value[collection] ?? {});
      var newValue = Map<String, dynamic>.from(value);
      newValue['docId'] = newId;

      final newDoc = KoozaDocument.fromMap(value).copyWith(
        timestamp: DateTime.now(),
        data: newValue,
        ttl: ttl,
      );
      collRef = collRef.setDoc(newId, newDoc);

      _subject.sink.add({collection: collRef.toMap()});
      await _box.put(collection, collRef.toMap());

      return newId;
    } catch (e) {
      throw KoozaError(
        code: 'KOOZA_SET_DOc',
        message: 'The doc ($value) could not be saved in Kooza',
      );
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> streamDocs(String collection) async* {
    if (!_subject.value.containsKey(collection)) {
      final result = _box.get(collection);
      if (result != null) {
        var subjectData = Map<String, dynamic>.from(_subject.value);
        subjectData[collection] = result;
        _subject.sink.add(subjectData);
      }
    }

    var collRef = KoozaCollection.fromMap(_subject.value[collection] ?? {});
    var newDocs = Map<String, KoozaDocument>.from(collRef.docs);
    newDocs.removeWhere((_, v) {
      if (v.ttl == null) return false;
      final storedDuration = DateTime.now().difference(v.timestamp);
      if (storedDuration.inMilliseconds >= v.ttl!.inMilliseconds) return true;
      return false;
    });

    collRef = collRef.copyWith(docs: newDocs);
    _subject.sink.add({collection: collRef.toMap()});
    await _box.put(collection, collRef.toMap());

    yield* _subject.stream.map((event) {
      if (event[collection] == null) return [];
      return KoozaCollection.fromMap(event[collection]).snapshots();
    });
  }

  @override
  Future<void> close() async {
    await _subject.close();
    await _box.close();
  }

  String _generateId() {
    final id = _rand.nextInt(100000000);
    return 'KOOZA${id + 100000000}';
  }
}
