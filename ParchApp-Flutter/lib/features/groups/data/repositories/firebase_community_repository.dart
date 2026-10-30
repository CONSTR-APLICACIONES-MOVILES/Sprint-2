import '../../domain/repositories/community_repository.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/data/mobile_api.dart';

class FirebaseCommunityRepository implements CommunityRepository {
  @override
  String? get sessionId => currentUserId?.call();
  final MobileApi api;
  final String project;
  final String? Function()? currentUserId;
  const FirebaseCommunityRepository(this.api,
      {this.currentUserId, this.project = 'default'});

  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> data) async {
    final uid = currentUserId?.call();
    if (currentUserId != null && uid == null) {
      throw StateError('Sign in to continue.');
    }
    final result = await api.call(name, data);
    if (currentUserId != null && uid != currentUserId!()) {
      throw StateError('Session changed.');
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> peers() async =>
      _rows(await call('getCommunityPeers', {}), 'peers');
  @override
  Future<List<Map<String, dynamic>>> invitations() async =>
      _rows(await call('getGroupInvitations', {}), 'invitations');
  @override
  Future<Map<String, dynamic>> details(String id) =>
      call('getGroupDetails', {'groupId': id});
  String _journalKey(String uid) => 'group-creation.v1.$project.$uid';
  @override
  Future<Map<String, dynamic>?> pendingCreation() async {
    final uid = currentUserId?.call();
    if (uid == null) return null;
    final preferences = await SharedPreferences.getInstance();
    if (currentUserId?.call() != uid) throw StateError('Session changed.');
    final raw = preferences.getString(_journalKey(uid));
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw));
  }

  @override
  Future<Map<String, dynamic>> create(
      String key, String name, String category, List<String> ids) async {
    final input = {
      'requestId': key,
      'name': name,
      'category': category,
      'inviteeIds': ids..sort()
    };
    final uid = currentUserId?.call();
    SharedPreferences? preferences;
    if (uid != null) {
      preferences = await SharedPreferences.getInstance();
      final prior = preferences.getString(_journalKey(uid));
      if (prior != null && prior != jsonEncode(input)) {
        throw StateError('Recover the pending group first.');
      }
      if (!await preferences.setString(_journalKey(uid), jsonEncode(input))) {
        throw StateError('Unable to save retry data. No request sent.');
      }
      if (uid != currentUserId?.call()) throw StateError('Session changed.');
    }
    Map<String, dynamic> receipt;
    try {
      receipt = await call('createGroup', input);
    } on FirebaseFunctionsException catch (e) {
      if ([
            'invalid-argument',
            'permission-denied',
            'unauthenticated',
            'resource-exhausted',
            'already-exists'
          ].contains(e.code) &&
          preferences != null) {
        try {
          await preferences.remove(_journalKey(uid!));
        } catch (_) {}
      }
      rethrow;
    }
    if (preferences != null) {
      try {
        await preferences.remove(_journalKey(uid!));
      } catch (_) {}
    }
    return receipt;
  }

  @override
  Future<void> respond(String id, String response) async {
    await call('respondGroupInvitation', {'groupId': id, 'response': response});
  }

  @override
  Future<void> revoke(String id, String invitee) async {
    await call('revokeGroupInvitation', {'groupId': id, 'inviteeId': invitee});
  }

  static List<Map<String, dynamic>> _rows(
          Map<String, dynamic> data, String key) =>
      (data[key] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
}
