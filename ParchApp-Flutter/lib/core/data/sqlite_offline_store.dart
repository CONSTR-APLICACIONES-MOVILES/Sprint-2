import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'offline_mobile_api.dart';

/// Relational envelope with one row per cached response / queued operation.
/// A transaction commits the complete snapshot, so a response cannot be shown
/// as durable while its pending command is missing from disk.
class SqliteOfflineStore implements OfflineStore {
  final Database database;
  final SharedPreferences? legacyPreferences;
  SqliteOfflineStore._(this.database, this.legacyPreferences);

  static Future<SqliteOfflineStore> open(
      {String? path,
      DatabaseFactory? factory,
      SharedPreferences? legacyPreferences}) async {
    final selected = factory ?? databaseFactory;
    final file =
        path ?? '${await selected.getDatabasesPath()}/parchapp-offline.sqlite';
    final db = await selected.openDatabase(file,
        options: OpenDatabaseOptions(
            version: 1,
            onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE offline_accounts ('
                  'namespace TEXT PRIMARY KEY NOT NULL)');
              await db.execute('CREATE TABLE cached_responses ('
                  'namespace TEXT NOT NULL REFERENCES offline_accounts(namespace) ON DELETE CASCADE, '
                  'request_key TEXT NOT NULL, lru_position INTEGER NOT NULL, entry_json TEXT NOT NULL, '
                  'PRIMARY KEY (namespace, request_key))');
              await db.execute('CREATE TABLE pending_operations ('
                  'namespace TEXT NOT NULL REFERENCES offline_accounts(namespace) ON DELETE CASCADE, '
                  'queue_position INTEGER NOT NULL, command_json TEXT NOT NULL, '
                  'PRIMARY KEY (namespace, queue_position))');
            }));
    return SqliteOfflineStore._(db, legacyPreferences);
  }

  Map<String, dynamic> _document(String raw) {
    final value = jsonDecode(raw);
    if (value is! Map ||
        value['cache'] is! Map ||
        value['pending'] is! List ||
        !(value['cache'] as Map).values.every((v) => v is Map) ||
        !(value['pending'] as List).every((v) => v is Map)) {
      throw const FormatException(
          'Invalid offline snapshot; saved data was preserved.');
    }
    return Map<String, dynamic>.from(value);
  }

  Future<void> _replace(
      Transaction tx, String key, Map<String, dynamic> doc) async {
    await tx.insert('offline_accounts', {'namespace': key},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await tx
        .delete('cached_responses', where: 'namespace = ?', whereArgs: [key]);
    await tx
        .delete('pending_operations', where: 'namespace = ?', whereArgs: [key]);
    final batch = tx.batch();
    var position = 0;
    for (final entry in (doc['cache'] as Map).entries) {
      batch.insert('cached_responses', {
        'namespace': key,
        'request_key': entry.key,
        'lru_position': position++,
        'entry_json': jsonEncode(entry.value),
      });
    }
    position = 0;
    for (final command in doc['pending'] as List) {
      batch.insert('pending_operations', {
        'namespace': key,
        'queue_position': position++,
        'command_json': jsonEncode(command),
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<String?> read(String key) => database.transaction((tx) async {
        final accounts = await tx.query('offline_accounts',
            where: 'namespace = ?', whereArgs: [key], limit: 1);
        if (accounts.isEmpty) {
          final legacy = legacyPreferences?.getString(key);
          if (legacy == null) return null;
          final doc = _document(legacy);
          await _replace(tx, key, doc);
          // Keep the old copy for recovery. The account marker prevents an empty
          // new queue from importing an old command again on future launches.
          return jsonEncode(doc);
        }
        final cache = await tx.query('cached_responses',
            where: 'namespace = ?', whereArgs: [key], orderBy: 'lru_position');
        final pending = await tx.query('pending_operations',
            where: 'namespace = ?',
            whereArgs: [key],
            orderBy: 'queue_position');
        return jsonEncode({
          'cache': {
            for (final row in cache)
              row['request_key'] as String:
                  jsonDecode(row['entry_json'] as String)
          },
          'pending': [
            for (final row in pending) jsonDecode(row['command_json'] as String)
          ],
        });
      });

  @override
  Future<void> write(String key, String value) async {
    final doc = _document(value);
    await database.transaction((tx) => _replace(tx, key, doc));
  }

  Future<void> close() => database.close();
}
