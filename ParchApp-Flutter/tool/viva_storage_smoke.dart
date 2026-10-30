// Native rehearsal only: no Firebase, no remote accounts, no user data.
// Uses a dedicated SQLite file; the ordinary app continues to use Firebase cloud.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/core/data/offline_mobile_api.dart';
import 'package:parchapp/core/data/offline_document_codec.dart';
import 'package:parchapp/core/data/sqlite_offline_store.dart';
import 'package:sqflite/sqflite.dart';

class RehearsalRemote implements MobileApi {
  int acknowledgements = 0;
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    if (name == 'respondToActivityInvitation') {
      acknowledgements++;
      return {'id': input['id'], 'response': input['response']};
    }
    if (name == 'getAlerts') {
      return {
        'alerts': [
          {
            'id': 'rehearsal-a',
            'title': 'Rehearsal invitation',
            'response': null,
            'isRead': false
          }
        ]
      };
    }
    if (name == 'getActivities') {
      return {
        'activities': [
          {'id': 'rehearsal-a', 'title': 'Rehearsal activity'}
        ]
      };
    }
    return {
      'id': name == 'getProfile' ? 'owner' : 'rehearsal-a',
      'name': 'Rehearsal student'
    };
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final report = <String, dynamic>{
    'kind': 'native-rehearsal',
    'remote': 'in-memory simulation, not cloud',
    'passed': false
  };
  SqliteOfflineStore? store;
  OfflineMobileApi? api;
  void require(bool value, String reason) {
    if (!value) throw StateError(reason);
  }

  try {
    final path = '${await getDatabasesPath()}/parchapp-viva-rehearsal.sqlite';
    store = await SqliteOfflineStore.open(path: path);
    const key = 'offline.v1.viva-rehearsal.owner';
    await store.write(key, jsonEncode({'cache': {}, 'pending': []}));
    final remote = RehearsalRemote();
    OfflineMobileApi create(SqliteOfflineStore disk) => OfflineMobileApi(
        remote: remote,
        store: disk,
        project: 'viva-rehearsal',
        currentUserId: () => 'owner');
    api = create(store);
    final reads = <String, Map<String, dynamic>>{
      'getActivities': {},
      'getActivity': {'activityId': 'rehearsal-a'},
      'getAlerts': {},
      'getProfile': {},
    };
    for (final entry in reads.entries) {
      await api.call(entry.key, entry.value);
    }
    await api.setForcedOffline(true);
    for (final entry in reads.entries) {
      require((await api.call(entry.key, entry.value))['offline'] == true,
          'Missing offline resource ${entry.key}');
    }
    await api.call('respondToActivityInvitation',
        {'id': 'rehearsal-a', 'response': 'accepted'});
    require(api.value.pending == 1, 'Response was not persisted');
    require(remote.acknowledgements == 0, 'Offline write reached remote');
    api.dispose();
    api = null;
    await store.close();
    store = null;
    store = await SqliteOfflineStore.open(path: path);
    api = create(store);
    await api.setForcedOffline(true);
    await api.refreshSession();
    require(api.value.pending == 1, 'Queue lost after database reopen');
    for (final entry in reads.entries) {
      require((await api.call(entry.key, entry.value))['offline'] == true,
          'Snapshot lost after reopen');
    }
    await api.setForcedOffline(false);
    require(api.value.pending == 0 && remote.acknowledgements == 1,
        'Replay did not remove acknowledged operation');
    const codec = OfflineDocumentCodec();
    final heavy = {
      'cache': {
        'large': {
          'data': {
            'alerts': List.generate(
                600,
                (i) => {
                      'id': '$i',
                      'title':
                          'A substantial rehearsal payload to activate the native worker'
                    })
          }
        }
      },
      'pending': []
    };
    final raw = await codec.encode(heavy);
    require(
        raw.length >= 32768, 'Payload did not reach isolate decode threshold');
    require(((await codec.decode(raw))['cache'] as Map).length == 1,
        'Native worker round trip failed');
    report.addAll({
      'passed': true,
      'sqliteSchemaVersion': await store.database.getVersion(),
      'offlineResources': reads.keys.toList(),
      'pendingAfterReopen': 1,
      'acknowledgements': remote.acknowledgements,
      'pendingAfterReplay': api.value.pending,
      'isolatePayloadCharacters': raw.length
    });
  } catch (error) {
    report['error'] = error.toString();
  } finally {
    api?.dispose();
    await store?.close();
  }
  debugPrint(
      'VIVA_SMOKE_${report['passed'] == true ? 'PASS' : 'FAIL'} ${jsonEncode(report)}');
  runApp(MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: const Text('Viva technical rehearsal')),
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LOCAL TEST DATA · NOT A CLOUD DEMO',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(report['passed'] == true ? 'PASS' : 'FAIL',
                        style: TextStyle(
                            fontSize: 36,
                            color: report['passed'] == true
                                ? Colors.green
                                : Colors.red)),
                    const SizedBox(height: 16),
                    SelectableText(
                        const JsonEncoder.withIndent('  ').convert(report)),
                    const SizedBox(height: 16),
                    const Text(
                        'Checks SQLite reopen and API resources, not navigation through four app screens. Physical-device and live-account checks remain required.'),
                  ])))));
}
