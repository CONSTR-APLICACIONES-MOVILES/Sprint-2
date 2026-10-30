// Native SDK smoke for the dedicated local demo, without manual phone actions.
import 'package:flutter/material.dart';
import 'package:parchapp/app/dependency_injection/firebase_dependencies.dart';
import 'package:parchapp/features/activities/data/data_sources/firebase_activity_data_source.dart';

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var result = 'FAIL';
  try {
    check(const bool.fromEnvironment('USE_FIREBASE_EMULATORS'),
        'Emulators required.');
    check(
        const String.fromEnvironment('FIREBASE_EMULATOR_PROJECT') ==
            'demo-parchapp-activity-metrics',
        'Dedicated demo project required.');
    final firebase = await FirebaseDependencies.initialize();
    Future<void> login(String role) async {
      await firebase.auth.signInWithEmailAndPassword(
          email: 'metrics.$role@example.test', password: 'MetricsQa123!');
      await firebase.mobile.refreshSession();
    }

    await login('owner');
    final owner = firebase.auth.currentUser!.uid;
    final source = FirebaseActivityDataSource(
        functions: firebase.functions,
        auth: firebase.auth,
        firestore: firebase.firestore,
        api: firebase.mobile,
        monitorFactory: firebase.creationMonitor);
    final before =
        await firebase.firestore.doc('insights/bq2_creation_reliability').get();
    final beforeAttempts = before.data()?['attempts'] as int? ?? 0;
    final activityId = await source.createActivity({
      'requestId': 'native-${DateTime.now().microsecondsSinceEpoch}',
      'groupId': 'metrics-qa',
      'fields': {
        'title': 'Native metrics QA',
        'category': 'study',
        'status': 'PROPOSED'
      },
    });
    final suggestions = await source.call('getActivityRecommendations',
        {'activityId': activityId, 'durationMinutes': 60, 'limit': 3});
    final candidates = suggestions['recommendations'] as List;
    check(candidates.isNotEmpty, 'Expected feasible slots in local demo.');
    await source.call('presentActivityRecommendations', {
      'activityId': activityId,
      'recommendationIds': candidates.map((r) => r['id']).toList()
    });
    await source.call('acceptActivityRecommendation',
        {'activityId': activityId, 'recommendationId': candidates.first['id']});
    await (await firebase.creationMonitor(owner)).flush();
    await login('peer');
    final participantDetail =
        await firebase.mobile.call('getActivity', {'activityId': activityId});
    check(participantDetail['createdBy'] == owner,
        'Participant cannot read shared activity.');
    await firebase.mobile.call('respondToActivityInvitation',
        {'id': activityId, 'response': 'accepted'});
    await login('owner');
    final detail = await source.call('getActivity', {'activityId': activityId});
    await source.call('updateActivityDetails', {
      'activityId': activityId,
      'expectedVersion': detail['version'],
      'fields': {
        'title': detail['title'],
        'category': detail['category'],
        'status': 'CONFIRMED',
        'date': detail['date'],
        'time': detail['time'],
        'location': detail['location']
      }
    });
    await firebase.functions.httpsCallable('refreshActivityInsights').call({});
    final after = (await firebase.firestore
            .doc('insights/bq2_creation_reliability')
            .get())
        .data()!;
    check(after['environment'] == 'test', 'Unexpected metric environment.');
    check(after['attempts'] == beforeAttempts + 1,
        'Native publication attempt missing or duplicated.');
    final confirmation = (await firebase.firestore
            .doc('insights/bq13_recommendation_confirmation')
            .get())
        .data()!;
    check((confirmation['pending'] as int) >= 3,
        'New candidates must remain immature.');
    check((await source.pendingPublication()) == null,
        'Acknowledged publication journal was not cleared.');
    await firebase.functions
        .httpsCallable('setUsername')
        .call({'username': 'activity.qa', 'clientUserId': owner});
    final search =
        await firebase.mobile.call('searchPeople', {'query': 'friend.'});
    final target = (search['people'] as List).single['id'] as String;
    final publicPerson =
        await firebase.mobile.call('getPublicPerson', {'userId': target});
    final sent = await firebase.mobile.call('changeFriendship', {
      'userId': target,
      'action': 'request',
      'expectedVersion': publicPerson['friendship']['version'],
      'clientUserId': owner
    });
    await firebase.auth.signInWithEmailAndPassword(
        email: 'social.peer@example.test', password: 'MetricsQa123!');
    await firebase.mobile.refreshSession();
    final accepted = await firebase.mobile.call('changeFriendship', {
      'userId': owner,
      'action': 'accept',
      'expectedVersion': sent['version'],
      'clientUserId': target
    });
    check(
        (await firebase.mobile.call('getFriends', {}))['relationships']
                .length ==
            1,
        'Friendship acceptance missing.');
    check(
        (await firebase.mobile.call('getScheduleFriends', {}))['friends']
            .isEmpty,
        'Friendship leaked schedule contacts.');
    await login('owner');
    await firebase.mobile.call('changeFriendship', {
      'userId': target,
      'action': 'remove',
      'expectedVersion': accepted['version'],
      'clientUserId': owner
    });
    check(
        (await firebase.mobile.call('getFriends', {}))['relationships'].isEmpty,
        'Friendship removal missing.');
    result =
        'PASS native BQ2/BQ13 + username/search/friendship: real Auth accounts, journal, recommendations, RSVP, confirmation, metrics, outside-group friendship and removal. activityId=$activityId';
    await firebase.auth.signOut();
  } catch (error, stack) {
    result = 'FAIL native BQ2/BQ13: $error';
    debugPrintStack(stackTrace: stack);
  }
  debugPrint(result);
  runApp(MaterialApp(
      home: Scaffold(
          body: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText(result))))));
}
