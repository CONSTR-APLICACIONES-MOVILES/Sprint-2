import 'publication_journal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/data/mobile_api.dart';
import '../models/activity_model.dart';
import 'activity_data_source.dart';

class FirebaseActivityDataSource
    implements ActivityDataSource, PublicationRecoveryDataSource {
  final FirebaseFunctions functions;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final MobileApi? api;
  final bool Function()? offline;
  FirebaseActivityDataSource(
      {required this.functions,
      required this.auth,
      required this.firestore,
      this.api,
      this.offline});
  void _requireOnline() {
    if (offline?.call() == true) {
      throw FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'This action requires a connection.');
    }
  }

  @override
  String? get currentUserId => auth.currentUser?.uid;

  @override
  Future<List<Map<String, dynamic>>> listGroups() async {
    _requireOnline();
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

  Future<PublicationJournal> _journal(String uid) async =>
      PublicationJournal(await SharedPreferences.getInstance(),
          project: firestore.app.options.projectId, uid: uid);
  @override
  Future<Map<String, dynamic>?> pendingPublication() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final journal = await _journal(uid);
    if (currentUserId != uid) throw StateError('Session changed.');
    return journal.read();
  }

  @override
  Future<String> createActivity(Map<String, dynamic> fields) async {
    _requireOnline();
    final uid = currentUserId;
    if (uid == null) throw FirebaseAuthException(code: 'unauthenticated');
    final journal = await _journal(uid);
    if (currentUserId != uid) throw StateError('Session changed.');
    await journal.write(fields);
    if (currentUserId != uid) throw StateError('Session changed.');
    try {
      final receipt = await call('publishActivity', fields);
      try {
        await journal.clear();
      } catch (_) {/* Server acknowledgement remains authoritative. */}
      return receipt['activityId'] as String;
    } on FirebaseException catch (error) {
      if (![
        'unavailable',
        'deadline-exceeded',
        'network-request-failed',
        'internal',
        'unknown',
        'cancelled'
      ].contains(error.code)) {
        await journal.clear();
      }
      rethrow;
    }
  }

  @override
  Future<void> updateActivity(String id, Map<String, dynamic> fields) {
    _requireOnline();
    return firestore.collection('activities').doc(id).update(fields);
  }

  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    if (api != null) return api!.call(name, input);
    final result = await functions.httpsCallable(name).call(input);
    return Map<String, dynamic>.from(result.data as Map);
  }

  @override
  Future<List<ActivityModel>> listActivities() async {
    if (api != null) {
      final result = await api!.call('getActivities', {});
      return [
        for (final raw in result['activities'] as List)
          ActivityModel({
            ...Map<String, dynamic>.from(raw as Map),
            'offline': result['offline'],
            'cachedAt': result['cachedAt']
          })
      ];
    }
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
          ActivityModel({
            ...doc.data(),
            'id': doc.id,
            if (doc.data()['startTime'] is Timestamp)
              'startTime': (doc.data()['startTime'] as Timestamp)
                  .toDate()
                  .toUtc()
                  .toIso8601String(),
            if (doc.data()['endTime'] is Timestamp)
              'endTime': (doc.data()['endTime'] as Timestamp)
                  .toDate()
                  .toUtc()
                  .toIso8601String(),
          })
    ];
  }
}
