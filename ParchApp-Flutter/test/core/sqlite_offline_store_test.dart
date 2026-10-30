import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:parchapp/core/data/sqlite_offline_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late SqliteOfflineStore store;
  late SharedPreferences preferences;
  Future<SqliteOfflineStore> open() => SqliteOfflineStore.open(
      path: '${directory.path}/offline.sqlite',
      factory: databaseFactoryFfi,
      legacyPreferences: preferences);
  final snapshot = {
    'cache': {
      'a': {
        'name': 'getProfile',
        'data': {'id': 'owner'},
        'savedAt': '2026-10-29T15:00:00Z'
      }
    },
    'pending': [
      {
        'name': 'respondToActivityInvitation',
        'input': {'id': 'a', 'response': 'accepted'},
        'blocked': true,
        'attempts': 2
      }
    ],
  };
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('parchapp-sqlite-test-');
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    store = await open();
  });
  tearDown(() async {
    await store.close();
    await directory.delete(recursive: true);
  });

  test(
      'migrates legacy cache and pending metadata once and survives real file reopen',
      () async {
    const key = 'offline.v1.project.owner';
    await preferences.setString(key, jsonEncode(snapshot));
    expect(jsonDecode((await store.read(key))!), snapshot);
    expect(await store.database.query('pending_operations'), hasLength(1));
    expect(preferences.getString(key), isNotNull);
    await store.close();
    store = await open();
    expect(jsonDecode((await store.read(key))!), snapshot);
    await store.write(key, jsonEncode({'cache': {}, 'pending': []}));
    await store.close();
    store = await open();
    expect(jsonDecode((await store.read(key))!)['pending'], isEmpty);
    // Retained Preferences must not resurrect an acknowledged old command.
    expect(preferences.getString(key), isNotNull);
  });
  test(
      'SQL failure rolls back both cache and queue instead of saving half a snapshot',
      () async {
    const key = 'offline.v1.project.owner';
    await store.write(key, jsonEncode(snapshot));
    await store.database.execute(
        "CREATE TRIGGER reject_second_command BEFORE INSERT ON pending_operations WHEN NEW.queue_position = 1 BEGIN SELECT RAISE(ABORT, 'injected disk failure'); END");
    await expectLater(
        store.write(
            key,
            jsonEncode({
              'cache': {},
              'pending': [{}, {}]
            })),
        throwsA(anything));
    expect(jsonDecode((await store.read(key))!), snapshot);
  });
  test(
      'account/project isolation and LRU order survive separate rows and reopen',
      () async {
    final ordered = {
      'cache': {'z': {}, 'a': {}, 'm': {}},
      'pending': []
    };
    await Future.wait([
      store.write('offline.v1.project.owner', jsonEncode(ordered)),
      store.write('offline.v1.other.owner', jsonEncode(snapshot)),
    ]);
    await store.close();
    store = await open();
    expect(
        (jsonDecode((await store.read('offline.v1.project.owner'))!)['cache']
                as Map)
            .keys,
        ['z', 'a', 'm']);
    expect(await store.read('offline.v1.project.someone-else'), isNull);
    expect(jsonDecode((await store.read('offline.v1.other.owner'))!), snapshot);
  });
  test(
      'corrupt legacy migration preserves source and does not create a namespace',
      () async {
    const key = 'offline.v1.project.owner';
    await preferences.setString(key, '{broken');
    await expectLater(store.read(key), throwsFormatException);
    expect(preferences.getString(key), '{broken');
    expect(await store.database.query('offline_accounts'), isEmpty);
  });
}
