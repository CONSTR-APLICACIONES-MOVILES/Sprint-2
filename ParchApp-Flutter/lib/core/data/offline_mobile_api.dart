import 'offline_document_codec.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mobile_api.dart';

abstract interface class OfflineStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PreferencesOfflineStore implements OfflineStore {
  final SharedPreferences preferences;
  const PreferencesOfflineStore(this.preferences);
  @override
  Future<String?> read(String key) async => preferences.getString(key);
  @override
  Future<void> write(String key, String value) async {
    if (!await preferences.setString(key, value)) {
      throw StateError('Unable to save offline data.');
    }
  }
}

class OfflineStatus {
  final bool forced, offline, syncing;
  final int pending;
  final String? error;
  const OfflineStatus(
      {this.forced = false,
      this.offline = false,
      this.syncing = false,
      this.pending = 0,
      this.error});
}

class PendingInvitation {
  final String id, title, response;
  final bool blocked;
  const PendingInvitation(
      {required this.id,
      required this.title,
      required this.response,
      required this.blocked});
}

/// One persisted document per project/user; no passwords or tokens are cached.
/// Only idempotent invitation commands may be queued. Other writes fail offline.
class OfflineMobileApi extends ValueNotifier<OfflineStatus>
    implements MobileApi {
  final MobileApi remote;
  final OfflineStore store;
  final String project;
  final String? Function() currentUserId;
  final DateTime Function() clock;
  final OfflineDocumentCodec codec;
  final int cacheCapacity;
  Future<void> _tail = Future.value();
  bool _flushing = false;
  bool _networkAvailable = true;
  String? _visibleUser;
  OfflineMobileApi(
      {required this.remote,
      required this.store,
      required this.project,
      required this.currentUserId,
      DateTime Function()? clock,
      this.codec = const OfflineDocumentCodec(),
      this.cacheCapacity = 64})
      : assert(cacheCapacity > 0),
        clock = clock ?? DateTime.now,
        super(const OfflineStatus());
  static const _reads = {
    'getFriends',
    'getProfile',
    'getAlerts',
    'getScheduleFriends',
    'getScheduleDay',
    'getActivity',
    'getActivities'
  };
  static const _queued = {'respondToActivityInvitation', 'markAlertsRead'};
  String _key(String uid) => 'offline.v1.$project.$uid';
  String _requestKey(String name, Map<String, dynamic> input) =>
      '$name:${sha256.convert(utf8.encode(jsonEncode(input)))}';
  Map<String, dynamic> _copy(Map value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  void _remember(Map cache, String key, Map entry) {
    cache.remove(key);
    cache[key] = entry;
    while (cache.length > cacheCapacity) {
      cache.remove(cache.keys.first);
    }
  }

  void _invalidateAfterMutation(Map saved, String name, Map input) {
    if ({'changeFriendship', 'setUsername'}.contains(name)) {
      (saved['cache'] as Map).removeWhere((_, entry) =>
          entry['name'] == 'getFriends' ||
          name == 'setUsername' && entry['name'] == 'getProfile');
    }
    const changes = {
      'publishActivity',
      'updateActivityDetails',
      'cancelActivity',
      'acceptActivityRecommendation',
      'modifyActivityRecommendation',
      'respondToActivityInvitation'
    };
    if (!changes.contains(name)) return;
    final id = input['activityId'] ?? input['id'];
    (saved['cache'] as Map).removeWhere((_, entry) =>
        entry['name'] == 'getActivities' ||
        entry['name'] == 'getActivity' &&
            (id == null ||
                entry['data']['id'] == id ||
                entry['data']['activityId'] == id) ||
        {'acceptActivityRecommendation', 'modifyActivityRecommendation'}
                .contains(name) &&
            entry['name'] == 'getScheduleDay');
  }

  Future<Map<String, dynamic>> _load(String uid) async {
    final raw = await store.read(_key(uid));
    return raw == null
        ? {'cache': <String, dynamic>{}, 'pending': <dynamic>[]}
        : await codec.decode(raw);
  }

  Future<T> _locked<T>(Future<T> Function() action) {
    final task = _tail.then((_) => action());
    _tail = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  String _user() {
    final uid = currentUserId();
    if (uid == null) throw StateError('Sign in to access saved data.');
    if (_visibleUser != uid) {
      _visibleUser = uid;
      value = OfflineStatus(forced: value.forced);
    }
    return uid;
  }

  void _check(String uid) {
    if (currentUserId() != uid) {
      throw StateError('Session changed. Reload this screen.');
    }
  }

  void _status(String uid,
      {bool? offline, bool? syncing, int? pending, String? error}) {
    if (currentUserId() == uid) {
      value = OfflineStatus(
          forced: value.forced,
          offline: offline ?? value.offline,
          syncing: syncing ?? value.syncing,
          pending: pending ?? value.pending,
          error: error);
    }
  }

  Future<void> refreshSession() async {
    final uid = currentUserId();
    if (uid == null) {
      _visibleUser = null;
      value = OfflineStatus(forced: value.forced);
      return;
    }
    _user();
    try {
      final saved = await _load(uid);
      _status(uid, pending: (saved['pending'] as List).length);
    } catch (_) {
      _status(uid, error: 'Saved offline data could not be read.');
    }
  }

  Future<void> setForcedOffline(bool forced) async {
    value =
        OfflineStatus(forced: forced, offline: forced, pending: value.pending);
    if (!forced) await flush();
  }

  void setNetworkAvailable(bool available) {
    _networkAvailable = available;
    value = OfflineStatus(
        forced: value.forced,
        offline: value.forced || !available,
        pending: value.pending,
        syncing: value.syncing,
        error: value.error);
    if (available) unawaited(flush(automatic: true));
  }

  bool _networkError(Object error) =>
      error is TimeoutException ||
      error is FirebaseFunctionsException &&
          {'unavailable', 'deadline-exceeded', 'network-request-failed'}
              .contains(error.code);

  void _apply(
      Map<String, dynamic> saved, String name, Map input, bool pending) {
    for (final entry in (saved['cache'] as Map).values) {
      if (entry['name'] != 'getAlerts') continue;
      for (final alert in entry['data']['alerts'] as List) {
        final matches = name == 'respondToActivityInvitation'
            ? alert['id'] == input['id']
            : (input['ids'] as List).contains(alert['id']);
        if (!matches) continue;
        alert['isRead'] = true;
        if (name == 'respondToActivityInvitation') {
          alert['response'] = input['response'];
          alert['pendingSync'] = pending;
        }
      }
    }
  }

  Map<String, dynamic> _overlay(
      Map<String, dynamic> data, String name, List pending) {
    final saved = {
      'cache': {
        'result': {'name': name, 'data': _copy(data)}
      }
    };
    for (final command in pending) {
      _apply(saved, command['name'] as String, command['input'] as Map, true);
    }
    return (saved['cache']!['result']!['data'] as Map).cast<String, dynamic>();
  }

  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    final uid = _user();
    if (!value.forced && _networkAvailable) {
      try {
        final result = await remote
            .call(
                name,
                (_queued.contains(name) ||
                        {'updateProfile', 'updatePresence', 'updatePreferences'}
                            .contains(name))
                    ? {...input, 'clientUserId': input['clientUserId'] ?? uid}
                    : input)
            .timeout(const Duration(seconds: 10));
        _check(uid);
        Map<String, dynamic> output = result;
        try {
          output = await _locked(() async {
            final saved = await _load(uid);
            if (_reads.contains(name)) {
              final cache = saved['cache'] as Map;
              _remember(cache, _requestKey(name, input), {
                'name': name,
                'data': result,
                'savedAt': clock().toUtc().toIso8601String()
              });
            } else if ({'updateProfile', 'updatePresence', 'updatePreferences'}
                .contains(name)) {
              _remember(saved['cache'] as Map, _requestKey('getProfile', {}), {
                'name': 'getProfile',
                'data': result,
                'savedAt': clock().toUtc().toIso8601String(),
              });
            } else if (_queued.contains(name)) {
              _apply(saved, name, input, false);
            }
            _invalidateAfterMutation(saved, name, input);
            // A cache failure must not report that a successful server write failed.
            try {
              await store.write(_key(uid), await codec.encode(saved));
            } catch (_) {
              _status(uid, error: 'Unable to persist the offline copy.');
            }
            return _overlay(result, name, saved['pending'] as List);
          });
        } catch (_) {
          _status(uid, error: 'Unable to persist the offline copy.');
        }
        _check(uid);
        _status(uid, offline: false, error: value.error);
        return output;
      } catch (error) {
        if (!_networkError(error)) rethrow;
        _status(uid, offline: true);
      }
    }
    _check(uid);
    return _locked(() async {
      final saved = await _load(uid);
      _check(uid);
      if (_reads.contains(name)) {
        final cached = (saved['cache'] as Map)[_requestKey(name, input)];
        if (cached == null) {
          throw StateError(
              'No saved data for this view. Open it online first.');
        }
        // A hit changes recency, never the server download time (savedAt).
        _remember(
            saved['cache'] as Map, _requestKey(name, input), cached as Map);
        try {
          await store.write(_key(uid), await codec.encode(saved));
        } catch (_) {
          _status(uid, error: 'Unable to persist cache recency.');
        }
        _status(uid, offline: true, pending: (saved['pending'] as List).length);
        return {
          ..._overlay(Map<String, dynamic>.from(cached['data'] as Map), name,
              saved['pending'] as List),
          'offline': true,
          'cachedAt': cached['savedAt']
        };
      }
      if (!_queued.contains(name)) {
        throw StateError('This action requires a connection.');
      }
      final pending = saved['pending'] as List;
      final duplicate = pending.any((c) =>
          c['name'] == name && jsonEncode(c['input']) == jsonEncode(input));
      if (!duplicate) {
        if (pending.length >= 100) {
          throw StateError('Sync pending responses before adding more.');
        }
        if (name == 'respondToActivityInvitation' &&
            pending.any(
                (c) => c['name'] == name && c['input']['id'] == input['id'])) {
          throw StateError('This invitation already has a pending response.');
        }
        pending.add({
          'name': name,
          'input': input,
          'queuedAt': DateTime.now().toUtc().toIso8601String()
        });
      }
      _apply(saved, name, input, true);
      await store.write(_key(uid), await codec.encode(saved));
      _check(uid);
      _status(uid, offline: true, pending: pending.length);
      return {'pending': true, ...input};
    });
  }

  /// Automatic triggers respect persisted backoff and blocked responses.
  /// An explicit retry bypasses the wait, optionally for one invitation only.
  Future<void> flush({bool automatic = false, String? invitationId}) async {
    if (_flushing ||
        value.forced ||
        !_networkAvailable ||
        currentUserId() == null) {
      return;
    }
    final uid = _user();
    _flushing = true;
    _status(uid, syncing: true);
    try {
      await _locked(() async {
        final saved = await _load(uid);
        final pending = saved['pending'] as List;
        _status(uid, pending: pending.length);
        for (final command in List.of(pending)) {
          if (value.forced || !_networkAvailable || currentUserId() != uid) {
            break;
          }
          if (invitationId != null &&
              (command['name'] != 'respondToActivityInvitation' ||
                  command['input']['id'] != invitationId)) {
            continue;
          }
          final nextAttempt =
              DateTime.tryParse(command['nextAttemptAt'] as String? ?? '');
          if (automatic &&
              (command['blocked'] == true ||
                  nextAttempt != null &&
                      clock().toUtc().isBefore(nextAttempt))) {
            _status(uid,
                error: command['blocked'] == true
                    ? 'A response needs review. Retry or discard pending responses.'
                    : 'Waiting before retrying the connection.');
            continue;
          }
          try {
            await remote.call(command['name'] as String, {
              ...Map<String, dynamic>.from(command['input'] as Map),
              'clientUserId': uid
            }).timeout(const Duration(seconds: 10));
            _check(uid);
            _apply(saved, command['name'] as String, command['input'] as Map,
                false);
            _invalidateAfterMutation(
                saved, command['name'] as String, command['input'] as Map);
            final position = pending.indexOf(command);
            pending.removeAt(position);
            try {
              await store.write(_key(uid), await codec.encode(saved));
            } catch (_) {
              pending.insert(position, command);
              rethrow;
            }
            _status(uid, offline: false, pending: pending.length);
          } catch (error) {
            final transient = _networkError(error);
            final attempts = (command['attempts'] as int? ?? 0) + 1;
            command['attempts'] = attempts;
            command['blocked'] = !transient;
            // 30, 60, 120, 240, then 300 seconds. Persist across restarts.
            final seconds = attempts >= 5 ? 300 : 30 * (1 << (attempts - 1));
            command['nextAttemptAt'] = clock()
                .toUtc()
                .add(Duration(seconds: seconds))
                .toIso8601String();
            try {
              await store.write(_key(uid), await codec.encode(saved));
            } catch (_) {
              // The original durable command remains available for replay.
            }
            _status(uid,
                offline: transient,
                pending: pending.length,
                error: transient
                    ? 'Waiting for a connection.'
                    : 'A response could not be synced. Retry or discard pending responses.');
            // Independent invitations can continue after a server rejection.
            // Transport and local persistence failures stop this replay pass.
            if (transient || error is! FirebaseFunctionsException) break;
          }
        }
        if (pending.any((command) => command['blocked'] == true)) {
          _status(uid,
              error: 'Some responses need review. Open pending invitations.');
        }
      });
    } catch (_) {
      _status(uid,
          error: 'Unable to read the pending queue. Saved data was preserved.');
    } finally {
      _flushing = false;
      _status(uid, syncing: false, error: value.error);
    }
  }

  Future<List<PendingInvitation>> pendingInvitations() async {
    final uid = _user();
    return _locked(() async {
      final saved = await _load(uid);
      _check(uid);
      return [
        for (final command in saved['pending'] as List)
          if (command['name'] == 'respondToActivityInvitation')
            PendingInvitation(
                id: command['input']['id'] as String,
                title:
                    _invitationTitle(saved, command['input']['id'] as String),
                response: command['input']['response'] as String,
                blocked: command['blocked'] == true),
      ];
    });
  }

  String _invitationTitle(Map<String, dynamic> saved, String id) {
    for (final entry in (saved['cache'] as Map).values) {
      if (entry['name'] != 'getAlerts') continue;
      for (final alert in entry['data']['alerts'] as List) {
        if (alert['id'] == id) {
          return alert['title'] as String? ?? 'Invitation $id';
        }
      }
    }
    return 'Invitation $id';
  }

  /// Removes only the local intent. It never overwrites the server response.
  Future<void> discardInvitation(String id) async {
    final uid = _user();
    await _locked(() async {
      final saved = await _load(uid);
      _check(uid);
      final pending = saved['pending'] as List;
      final removed = pending
          .where((c) =>
              c['name'] == 'respondToActivityInvitation' &&
              c['input']['id'] == id)
          .length;
      if (removed == 0) return;
      pending.removeWhere((c) =>
          c['name'] == 'respondToActivityInvitation' && c['input']['id'] == id);
      // Older cache documents contain optimistic responses. Invalidate them
      // rather than presenting a discarded local response as authoritative.
      (saved['cache'] as Map)
          .removeWhere((_, entry) => entry['name'] == 'getAlerts');
      await store.write(_key(uid), await codec.encode(saved));
      _check(uid);
      _status(uid, pending: pending.length);
    });
  }

  Future<void> discardPending() async {
    final uid = _user();
    await _locked(() async {
      final saved = await _load(uid);
      saved['pending'] = [];
      (saved['cache'] as Map)
          .removeWhere((_, entry) => entry['name'] == 'getAlerts');
      await store.write(_key(uid), await codec.encode(saved));
      _status(uid, pending: 0);
    });
  }
}
