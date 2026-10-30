import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/features/alerts/data/repositories/firebase_alerts_repository.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/domain/use_cases/manage_alerts.dart';
import 'package:parchapp/features/alerts/presentation/view_models/alerts_view_model.dart';
import 'package:parchapp/features/alerts/presentation/views/alerts_view.dart';

class _Api implements MobileApi {
  final bool digest;
  bool read = false, fail = false;
  String? response = 'declined';
  final commands = <Map<String, dynamic>>[];
  _Api({this.digest = true});
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    if (name == 'getAlerts') {
      return {
        'alerts': [
          {
            'id': 'test-alert',
            'kind': digest ? 'digest' : 'invitation',
            'title':
                digest ? 'Gabriel accepted your friend request' : 'Study plan',
            'description': 'A real notification',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'isRead': read,
            'response': digest ? null : response
          }
        ]
      };
    }
    commands.add({'name': name, ...input});
    if (fail) throw StateError('Offline');
    if (name == 'markNotificationEventsRead') read = true;
    if (name == 'respondToActivityInvitation') response = input['response'];
    return {};
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('dismiss and mark-read persist across repository recreation', () async {
    for (final swipe in [true, false]) {
      final api = _Api();
      final live = FirebaseAlertsRepository(api);
      final alert = (await live.getAlerts()).single;
      if (swipe) {
        await live.respond(alert.id, AlertResponse.dismissed);
      } else {
        await live.markAllRead();
      }
      expect(await FirebaseAlertsRepository(api).getAlerts(), isEmpty);
    }
  });
  test('failed dismissal keeps the notification available for retry', () async {
    final api = _Api();
    final live = FirebaseAlertsRepository(api);
    final alert = (await live.getAlerts()).single;
    api.fail = true;
    await expectLater(
        live.respond(alert.id, AlertResponse.dismissed), throwsStateError);
    expect((await live.getAlerts()).single.id, alert.id);
  });
  test('an invitation supports every change of mind with the prior response',
      () async {
    final api = _Api(digest: false);
    final useCase = ManageAlerts(FirebaseAlertsRepository(api));
    var alert = (await useCase.load()).single;
    for (final response in [
      AlertResponse.maybe,
      AlertResponse.accepted,
      AlertResponse.declined
    ]) {
      final old = alert.response;
      alert = (await useCase.respond(alert, response)).single;
      expect(api.commands.last['expectedResponse'], old?.name);
      expect(alert.response, response);
    }
  });
  testWidgets('swiping an accepted friendship removes it after persistence',
      (tester) async {
    final api = _Api();
    final model = AlertsViewModel(ManageAlerts(FirebaseAlertsRepository(api)));
    await tester.pumpWidget(MaterialApp(home: AlertsView(viewModel: model)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('Gabriel accepted your friend request'), findsNothing);
    expect(api.read, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
}
