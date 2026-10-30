import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:parchapp/features/expansions/domain/repositories/expansion_repository.dart';
import 'package:parchapp/features/expansions/presentation/views/social_views.dart';

class SocialFake implements ExpansionRepository {
  String? uid = 'a';
  @override
  String? get sessionId => uid;
  final calls = <(String, Map<String, dynamic>)>[];
  Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)? handler;
  @override
  Future<Map<String, dynamic>> request(
      String name, Map<String, dynamic> input) async {
    calls.add((name, {...input}));
    return handler!(name, input);
  }
}

Map<String, dynamic> person() => {
      'id': 'b',
      'name': 'Bob',
      'username': 'bobby',
      'self': false,
      'friendship': {
        'state': 'pending',
        'version': 'v1',
        'direction': 'incoming'
      }
    };
void main() {
  testWidgets(
      'username collision keeps typed value and sends normalized input to server boundary',
      (tester) async {
    final fake = SocialFake()
      ..handler = (name, input) async {
        if (name == 'getProfile') return {'username': null};
        throw FirebaseFunctionsException(
            code: 'already-exists', message: 'This username is already taken.');
      };
    await tester.pumpWidget(MaterialApp(home: UsernameView(repository: fake)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'taken_name');
    await tester.pump();
    await tester.tap(find.text('Save username'));
    await tester.pumpAndSettle();
    expect(find.text('This username is already taken.'), findsOneWidget);
    expect(find.text('taken_name'), findsOneWidget);
    expect(fake.calls.last.$2['clientUserId'], 'a');
  });
  testWidgets('late search response never replaces newer username query',
      (tester) async {
    final fake = SocialFake(), old = Completer<Map<String, dynamic>>();
    fake.handler = (name, input) async => input['query'] == 'al'
        ? old.future
        : {
            'people': [
              {'id': 'b', 'name': 'Bob', 'username': 'bobby'}
            ],
            'cursor': null
          };
    await tester.pumpWidget(
        MaterialApp(home: FriendsView(repository: fake, searchOnly: true)));
    await tester.enterText(find.byType(TextField), 'al');
    await tester.pump(const Duration(milliseconds: 310));
    await tester.enterText(find.byType(TextField), 'bo');
    await tester.pump(const Duration(milliseconds: 310));
    await tester.pump();
    expect(find.text('Bob'), findsOneWidget);
    old.complete({
      'people': [
        {'id': 'c', 'name': 'Old Alice', 'username': 'alice'}
      ],
      'cursor': null
    });
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Old Alice'), findsNothing);
  });
  testWidgets(
      'friend acceptance waits for acknowledgement and retries identical version after lost ACK',
      (tester) async {
    final fake = SocialFake();
    var attempts = 0;
    fake.handler = (name, input) async {
      if (name == 'getPublicPerson') return person();
      if (++attempts == 1) {
        throw FirebaseFunctionsException(
            code: 'unavailable', message: 'No acknowledgement.');
      }
      return {'state': 'accepted', 'version': 'v2', 'direction': 'incoming'};
    };
    await tester.pumpWidget(
        MaterialApp(home: PublicPersonView(repository: fake, userId: 'b')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept request'));
    await tester.pumpAndSettle();
    expect(find.text('Friends'), findsNothing);
    expect(find.text('Retry action'), findsOneWidget);
    await tester.tap(find.text('Retry action'));
    await tester.pumpAndSettle();
    expect(find.text('Friends'), findsOneWidget);
    final mutations =
        fake.calls.where((c) => c.$1 == 'changeFriendship').toList();
    expect(mutations, hasLength(2));
    expect(mutations[0].$2, mutations[1].$2);
  });
  testWidgets(
      'account switch hides prior public relationship and prevents mutation',
      (tester) async {
    final fake = SocialFake()..handler = (name, input) async => person();
    await tester.pumpWidget(
        MaterialApp(home: PublicPersonView(repository: fake, userId: 'b')));
    await tester.pumpAndSettle();
    fake.uid = 'different';
    await tester.tap(find.text('Refresh profile'));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsNothing);
    expect(find.text('Accept request'), findsNothing);
    expect(find.text('Session changed. Reopen this screen.'), findsOneWidget);
    expect(fake.calls, hasLength(1));
  });
  testWidgets(
      'cached Friends shows age and incoming request state at narrow accessible layout',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fake = SocialFake()
      ..handler = (name, input) async => {
            'relationships': [
              {
                'person': {'id': 'b', 'name': 'Bob', 'username': 'bobby'},
                'state': 'pending',
                'direction': 'incoming',
                'version': 'v1'
              }
            ],
            'cursor': null,
            'offline': true,
            'cachedAt': '2026-10-30T05:00:00Z'
          };
    await tester.pumpWidget(MaterialApp(
        builder: (_, child) => MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: child!),
        home: FriendsView(repository: fake)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved copy:'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Incoming request'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
