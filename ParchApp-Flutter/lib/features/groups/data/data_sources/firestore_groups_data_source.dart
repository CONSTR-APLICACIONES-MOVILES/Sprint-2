import '../../../../core/data/mobile_api.dart';
import 'dart:async';
import '../../../../core/domain/data_freshness.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'groups_data_source.dart';

class FirestoreGroupsDataSource
    implements GroupsDataSource, CacheAwareRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final MobileApi? api;
  final bool Function()? canAttemptRemote;
  @override
  DataFreshness freshness = const DataFreshness();
  String? _owner;
  DateTime? _savedAt;
  bool _usedCache = false;
  FirestoreGroupsDataSource(this.firestore, this.auth,
      {this.api, this.canAttemptRemote});

  Future<QuerySnapshot<Map<String, dynamic>>> _read(
      Query<Map<String, dynamic>> query) async {
    if (canAttemptRemote?.call() != false && !_usedCache) {
      try {
        return await query
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 6));
      } on TimeoutException {
        _usedCache = true;
      } on FirebaseException catch (e) {
        if (!{'unavailable', 'deadline-exceeded', 'network-request-failed'}
            .contains(e.code)) {
          rethrow;
        }
        _usedCache = true;
      }
    } else {
      _usedCache = true;
    }
    freshness = DataFreshness(offline: true, cachedAt: _savedAt);
    return query
        .get(const GetOptions(source: Source.cache))
        .timeout(const Duration(seconds: 2));
  }

  @override
  String? get currentUserId => auth.currentUser?.uid;

  String _requireUser() {
    final uid = currentUserId;
    if (uid == null) throw StateError('Sign in to view your groups.');
    return uid;
  }

  @override
  Future<List<Map<String, dynamic>>> listGroups() async {
    final uid = _requireUser();
    if (_owner != uid) {
      _savedAt = null;
      _owner = uid;
      freshness = const DataFreshness();
    }
    _usedCache = canAttemptRemote?.call() == false;
    freshness = DataFreshness(offline: _usedCache, cachedAt: _savedAt);
    final groups = await _read(
        firestore.collection('groups').where('memberIds', arrayContains: uid));
    final rows = await Future.wait(groups.docs.map((group) async {
      final latest = await _read(firestore
          .collection('activities')
          .where('groupId', isEqualTo: group.id)
          .orderBy('createdAt', descending: true)
          .limit(1));
      final activity = latest.docs.firstOrNull;
      final createdAt = activity?.data()['createdAt'];
      Map<String, dynamic>? details;
      if (activity != null &&
          api != null &&
          (!_usedCache || canAttemptRemote?.call() == false)) {
        try {
          details = await api!.call('getActivity', {'activityId': activity.id});
          if (details['offline'] == true) _usedCache = true;
        } on StateError {
          if (!_usedCache) rethrow;
          // The group is still useful when this activity was never opened online.
        }
      }
      final participants = details?['participants'] as List? ?? [];
      if (currentUserId != uid) throw StateError('Session changed.');
      return <String, dynamic>{
        ...group.data(),
        'id': group.id,
        'activityAttendanceUnavailable':
            activity != null && api != null && details == null,
        if (details != null) ...{
          'activityAttendance': true,
          'activityCancelled': details['cancelled'] == true,
          'activityOrganizedByMe': details['createdBy'] == uid,
          'activityInvited': participants.any((p) => p['id'] == uid),
          'activityResponse': participants
              .where((p) => p['id'] == uid)
              .firstOrNull?['activityRsvpStatus'],
          'activityGoingIds': [
            for (final person in participants)
              if (person['activityRsvpStatus'] == 'accepted') person['id']
          ],
          'activityMaybeCount': participants
              .where((p) => p['activityRsvpStatus'] == 'maybe')
              .length,
          'activityDeclinedCount': participants
              .where((p) => p['activityRsvpStatus'] == 'declined')
              .length,
          'activityParticipantIds': [
            for (final person in participants) person['id']
          ],
        },
        if (activity != null && createdAt is Timestamp) ...{
          'invitationId': activity.id,
          'invitationSentAt': createdAt.toDate(),
          'activityCategory': activity.data()['category'],
          'activityTitle': activity.data()['title'],
          if (activity.data()['startTime'] is Timestamp)
            'activityStartsAt':
                (activity.data()['startTime'] as Timestamp).toDate(),
          'activityLocation': activity.data()['locationDetails'],
        },
      };
    }));
    if (currentUserId != uid) throw StateError('Session changed.');
    if (!_usedCache) _savedAt = DateTime.now().toUtc();
    freshness = DataFreshness(offline: _usedCache, cachedAt: _savedAt);
    if (_usedCache && rows.isEmpty) {
      throw StateError(
          'You are offline. No saved groups are available on this device.');
    }
    return rows;
  }

  @override
  Future<Map<String, dynamic>> confirmGoing(String groupId) => Future.error(
      StateError('Respond to the activity invitation instead of the group.'));
}
