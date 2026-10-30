import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/expansions/domain/repositories/expansion_repository.dart';
import 'package:parchapp/features/expansions/presentation/views/activity_participants_view.dart';
import 'package:parchapp/shared/widgets/inline_error_notice.dart';

class _Repository implements ExpansionRepository {
  final bool organizer;
  bool joined = false, rejected = false;
  final calls = <Map<String, dynamic>>[];
  _Repository({this.organizer = false});
  @override
  String get sessionId => 'viewer';
  @override
  Future<Map<String, dynamic>> request(
      String name, Map<String, dynamic> input) async {
    if (name == 'getActivityParticipants') {
      return {
        'version': 'version-1',
        'groupId': 'team',
        'canManage': organizer,
        'canInviteFriends': organizer,
        'canJoin': !joined,
        'joined': joined,
        'cancelled': false,
        'members': [
          {
            'id': 'owner',
            'name': 'Owner',
            'organizer': true,
            'invited': true,
            'response': 'accepted'
          },
          if (organizer)
            {
              'id': 'member',
              'name': 'Member',
              'organizer': false,
              'invited': false,
              'response': null
            }
        ]
      };
    }
    if (name == 'getFriends') {
      return {
        'relationships': [
          {
            'state': 'accepted',
            'person': {
              'id': 'friend',
              'name': 'My Friend',
              'username': 'friend'
            }
          }
        ],
        'cursor': null
      };
    }
    calls.add({'name': name, ...input});
    if (rejected) throw StateError('Rejected by server');
    joined = true;
    return {'saved': true};
  }
}

void main() {
  testWidgets(
      'member joins with the displayed version and never sees management controls',
      (tester) async {
    final repo = _Repository();
    await tester.pumpWidget(MaterialApp(
        home: ActivityParticipantsView(repository: repo, activityId: 'plan')));
    await tester.pumpAndSettle();
    expect(find.text('Invite to activity'), findsNothing);
    expect(find.text('Remove participant'), findsNothing);
    await tester.tap(find.text('Join activity'));
    await tester.pumpAndSettle();
    expect(repo.calls.single, {
      'name': 'changeActivityParticipants',
      'activityId': 'plan',
      'action': 'join',
      'expectedVersion': 'version-1',
      'clientUserId': 'viewer'
    });
    expect(find.text('View Invitation'), findsOneWidget);
  });
  testWidgets(
      'rejected join remains unjoined and presents an accessible error notice',
      (tester) async {
    final repo = _Repository()..rejected = true;
    await tester.pumpWidget(MaterialApp(
        home: ActivityParticipantsView(repository: repo, activityId: 'plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join activity'));
    await tester.pumpAndSettle();
    expect(find.byType(InlineErrorNotice), findsOneWidget);
    expect(find.text('Join activity'), findsOneWidget);
    expect(find.text('View Invitation'), findsNothing);
  });
  testWidgets(
      'organizer can invite a group member and invite an accepted friend to the group',
      (tester) async {
    final repo = _Repository(organizer: true);
    await tester.pumpWidget(MaterialApp(
        home: ActivityParticipantsView(repository: repo, activityId: 'plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite to activity'));
    await tester.pumpAndSettle();
    expect(repo.calls.single['action'], 'invite');
    expect(repo.calls.single['userId'], 'member');
    await tester.scrollUntilVisible(find.text('Invite to group'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite to group'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, {
      'name': 'inviteGroupFriend',
      'groupId': 'team',
      'userId': 'friend',
      'clientUserId': 'viewer'
    });
    expect(find.text('Sent'), findsOneWidget);
  });
}
