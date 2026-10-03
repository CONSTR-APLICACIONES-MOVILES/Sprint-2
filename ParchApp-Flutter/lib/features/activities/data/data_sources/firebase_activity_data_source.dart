import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_model.dart';
import 'activity_data_source.dart';

class FirebaseActivityDataSource implements ActivityDataSource {
  final FirebaseFunctions functions;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  FirebaseActivityDataSource(
      {required this.functions, required this.auth, required this.firestore});

  @override
  String? get currentUserId => auth.currentUser?.uid;

  @override
  Future<List<Map<String, dynamic>>> listGroups() async {
    final uid = currentUserId;
    if (uid == null) throw FirebaseAuthException(code: 'unauthenticated');
    final groups = await firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .get();
    return [
      for (final doc in groups.docs) {...doc.data(), 'id': doc.id}
    ];
  }

  @override
  Future<String> createActivity(Map<String, dynamic> fields) async {
    final uid = currentUserId;
    if (uid == null) throw FirebaseAuthException(code: 'unauthenticated');
    final ref = firestore.collection('activities').doc();
    await ref.set({
      ...fields,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp()
    });
    return ref.id;
  }

  @override
  Future<void> updateActivity(String id, Map<String, dynamic> fields) =>
      firestore.collection('activities').doc(id).update(fields);

  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    final result = await functions.httpsCallable(name).call(input);
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Future<List<ActivityModel>> listActivities() async {
    final uid = currentUserId;
    if (uid == null) throw FirebaseAuthException(code: 'unauthenticated');
    final groups = await firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .get();
    final pages = await Future.wait(groups.docs.map((group) => firestore
        .collection('activities')
        .where('groupId', isEqualTo: group.id)
        .orderBy('createdAt', descending: true)
        .get()));
    return [
      for (final page in pages)
        for (final doc in page.docs)
          ActivityModel({...doc.data(), 'id': doc.id})
    ];
  }
}
