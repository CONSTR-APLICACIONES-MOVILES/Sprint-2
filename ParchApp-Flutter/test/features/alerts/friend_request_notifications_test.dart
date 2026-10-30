import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/features/alerts/data/repositories/firebase_alerts_repository.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/presentation/widgets/alert_card.dart';

class _Api implements MobileApi {
  final calls = <(String, Map<String, dynamic>)>[];
  bool stale = false;
  Completer<Map<String, dynamic>>? acknowledgement;
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    calls.add((name, input));
    if (name == 'getAlerts') {
      return {
        'alerts': [
          {
            'id': 'friend-test',
            'kind': 'friendRequest',
            'title': 'Alice Example sent you a friend request',
            'description': '@alice.example',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'requesterId': 'alice',
            'requesterName': 'Alice Example',
            'requesterUsername': 'alice.example',
            'friendshipVersion': 'version-one',
            'isRead': false,
          }
        ]
      };
    }
    if (name == 'changeFriendship') {
      if (stale) {
        throw FirebaseFunctionsException(
            code: 'aborted', message: 'Friendship changed.');
      }
      return acknowledgement == null
          ? {'state': 'accepted'}
          : await acknowledgement!.future;
    }
    return {};
  }
}

void main() {
  for (final response in [AlertResponse.accepted, AlertResponse.declined]) {
    test(
        'friend request ${response.name} uses the requester and frozen version, not the activity endpoint',
        () async {
      final api = _Api();
      final live = FirebaseAlertsRepository(api, currentUserId: () => 'bob');
      final alert = (await live.getAlerts()).single;
      expect(alert.requesterName, 'Alice Example');
      await live.markAllRead();
      expect(api.calls.last.$1, 'markNotificationEventsRead');
      final result = await live.respond(alert.id, response);
      expect(api.calls.last.$1, 'changeFriendship');
      expect(api.calls.last.$2, {
        'userId': 'alice',
        'action': response == AlertResponse.accepted ? 'accept' : 'decline',
        'expectedVersion': 'version-one',
        'clientUserId': 'bob'
      });
      expect(result.single.response, response);
      expect(result.single.friendshipVersion, 'version-one');
      expect(
          api.calls.any((c) => c.$1 == 'respondToActivityInvitation'), false);
    });
  }
  test(
      'a stale or withdrawn request is not shown as accepted on a rejected response',
      () async {
    final api = _Api();
    final live = FirebaseAlertsRepository(api, currentUserId: () => 'bob');
    final alert = (await live.getAlerts()).single;
    api.stale = true;
    await expectLater(live.respond(alert.id, AlertResponse.accepted),
        throwsA(isA<FirebaseFunctionsException>()));
    expect((await live.markAllRead()).single.response, isNull);
  });
  test(
      'switching accounts while accepting cannot expose the previous account notification',
      () async {
    var uid = 'bob';
    final api = _Api();
    final repo = FirebaseAlertsRepository(api, currentUserId: () => uid);
    final alert = (await repo.getAlerts()).single;
    api.acknowledgement = Completer<Map<String, dynamic>>();
    final response = repo.respond(alert.id, AlertResponse.accepted);
    final expected = expectLater(response, throwsStateError);
    uid = 'other-account';
    api.acknowledgement!.complete({'state': 'accepted'});
    await expected;
    expect(await repo.markAllRead(), isEmpty);
  });
  testWidgets(
      'real friend notification offers consent actions and real identity without fake presence',
      (tester) async {
    final api = _Api();
    final live = FirebaseAlertsRepository(api, currentUserId: () => 'bob');
    final alert = (await live.getAlerts()).single;
    AlertResponse? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: AlertCard(
      alert: alert,
      busy: false,
      onRespond: (r) => selected = r,
      onCreateActivity: () {},
      onProfile: () {},
      onDetails: () {},
    )))));
    expect(
        find.text('Alice Example sent you a friend request'), findsOneWidget);
    expect(find.text('AE'), findsOneWidget);
    expect(find.text('● Active Now'), findsNothing);
    expect(find.textContaining('Hey Alex'), findsNothing);
    expect(find.text('View activity'), findsNothing);
    expect(find.byTooltip('View requester profile'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    expect(selected, AlertResponse.accepted);
    await tester.tap(find.text('Decline'));
    expect(selected, AlertResponse.declined);
  });
}
