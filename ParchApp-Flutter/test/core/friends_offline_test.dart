import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/core/data/offline_mobile_api.dart';

class FriendsStore implements OfflineStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class FriendsRemote implements MobileApi {
  int changes = 0;
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    if (name == 'getFriends') {
      return {
        'relationships': [
          {
            'person': {'id': 'peer', 'name': 'Peer', 'username': 'peer'},
            'state': 'accepted'
          }
        ],
        'cursor': null
      };
    }
    changes++;
    return {'state': 'removed', 'version': 'v2'};
  }
}

void main() {
  test(
      'Friends snapshot survives restart, remains UID-scoped and cannot queue offline friendship changes',
      () async {
    final disk = FriendsStore(), remote = FriendsRemote();
    var uid = 'owner';
    OfflineMobileApi create() => OfflineMobileApi(
        remote: remote, store: disk, project: 'demo', currentUserId: () => uid);
    final first = create();
    await first.call('getFriends', {});
    first.dispose();
    final restored = create();
    await restored.setForcedOffline(true);
    final saved = await restored.call('getFriends', {});
    expect(saved['offline'], true);
    expect(saved['cachedAt'], isNotNull);
    expect(saved['relationships'], hasLength(1));
    await expectLater(
        restored.call('changeFriendship',
            {'userId': 'peer', 'action': 'remove', 'expectedVersion': 'v1'}),
        throwsStateError);
    expect(remote.changes, 0);
    expect(restored.value.pending, 0);
    uid = 'other';
    await expectLater(restored.call('getFriends', {}), throwsStateError);
    restored.dispose();
  });
  test(
      'acknowledged friendship mutation invalidates saved list instead of showing stale acceptance offline',
      () async {
    final api = OfflineMobileApi(
        remote: FriendsRemote(),
        store: FriendsStore(),
        project: 'demo',
        currentUserId: () => 'owner');
    await api.call('getFriends', {});
    await api.call('changeFriendship',
        {'userId': 'peer', 'action': 'remove', 'expectedVersion': 'v1'});
    await api.setForcedOffline(true);
    await expectLater(api.call('getFriends', {}), throwsStateError);
    api.dispose();
  });
}
