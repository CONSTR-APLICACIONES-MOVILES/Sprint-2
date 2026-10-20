import '../../../../core/data/mobile_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'groups_data_source.dart';

class FirestoreGroupsDataSource implements GroupsDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final MobileApi? api;
  const FirestoreGroupsDataSource(this.firestore, this.auth, {this.api});

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
    final groups = await firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .get();
    return Future.wait(groups.docs.map((group) async {
      final latest = await firestore
          .collection('activities')
          .where('groupId', isEqualTo: group.id)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      final activity = latest.docs.firstOrNull;
      final createdAt = activity?.data()['createdAt'];
      final details = activity == null || api == null
          ? null
          : await api!.call('getActivity', {'activityId': activity.id});
      final participants = details?['participants'] as List? ?? [];
      if (currentUserId != uid) throw StateError('Session changed.');
      return <String, dynamic>{
        ...group.data(),
        'id': group.id,
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
        },
      };
    }));
  }

  @override
  Future<Map<String, dynamic>> confirmGoing(String groupId) => Future.error(
      StateError('Respond to the activity invitation instead of the group.'));
}
