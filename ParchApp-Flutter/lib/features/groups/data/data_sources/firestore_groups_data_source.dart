import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'groups_data_source.dart';

class FirestoreGroupsDataSource implements GroupsDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  const FirestoreGroupsDataSource(this.firestore, this.auth);

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
      return <String, dynamic>{
        ...group.data(),
        'id': group.id,
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
  Future<Map<String, dynamic>> confirmGoing(String groupId) async {
    final uid = _requireUser();
    final ref = firestore.collection('groups').doc(groupId);
    return firestore.runTransaction((transaction) async {
      final data = (await transaction.get(ref)).data();
      if (data == null) throw StateError('This group no longer exists.');
      final members = List<String>.from(data['memberIds'] as List);
      if (!members.contains(uid)) {
        throw StateError('Group membership required.');
      }
      final going = List<String>.from(data['goingIds'] as List);
      final maybe = List<String>.from(data['maybeIds'] as List);
      // Atomic transforms preserve the Java client's simultaneous responses.
      transaction.update(ref, {
        'goingIds': FieldValue.arrayUnion([uid]),
        'maybeIds': FieldValue.arrayRemove([uid]),
      });
      return <String, dynamic>{
        ...data,
        'id': groupId,
        'goingIds': {...going, uid}.toList(),
        'maybeIds': maybe.where((id) => id != uid).toList(),
      };
    });
  }
}
