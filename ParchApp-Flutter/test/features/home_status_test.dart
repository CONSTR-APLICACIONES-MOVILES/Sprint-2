import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parchapp/features/home/domain/entities/quick_status.dart';
import 'package:parchapp/features/home/data/repositories/preferences_quick_status_repository.dart';
import 'package:parchapp/features/home/presentation/views/home_view.dart';
import 'package:parchapp/features/home/presentation/widgets/quick_status_sheet.dart';
import 'package:parchapp/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:parchapp/features/profile/domain/entities/profile_user.dart';
import 'package:parchapp/features/activities/domain/entities/activity_summary.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_list_view_model.dart';

void main() {
  test(
      'quick status survives repository recreation, keeps blank fields and isolates accounts/projects',
      () async {
    SharedPreferences.setMockInitialValues({});
    const store = PreferencesQuickStatusRepository('project-one');
    await store.save('alice', '4:00 PM', 'Library Study');
    final saved = await const PreferencesQuickStatusRepository('project-one')
        .load('alice');
    expect(saved.freeUntil, '4:00 PM');
    expect(saved.nextActivity, 'Library Study');
    final merged = await store.save('alice', '  ', 'Gym');
    expect(merged.freeUntil, '4:00 PM');
    expect(merged.nextActivity, 'Gym');
    expect((await store.load('bob')).nextActivity, isEmpty);
    expect(
        (await const PreferencesQuickStatusRepository('project-two')
                .load('alice'))
            .nextActivity,
        isEmpty);
  });
  testWidgets(
      'availability bubble uses profile state and opens the status editor',
      (tester) async {
    final user =
        (await tester.runAsync(() => MockProfileRepository().getProfile()))!
            .copyWith(status: AvailabilityStatus.inTransit);
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
        home: HomeView(profile: user, onManageStatus: () => opened++)));
    final bubble = find.byKey(const ValueKey('availability-status-bubble'));
    expect(find.descendant(of: bubble, matching: find.text('In transit')),
        findsOneWidget);
    await tester.tap(bubble);
    expect(opened, 1);
    await tester.pumpWidget(MaterialApp(
        home: HomeView(
            profile: user.copyWith(
                statusExpiresAt:
                    DateTime.now().subtract(const Duration(minutes: 1))))));
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('availability-status-bubble')),
            matching: find.text('Offline')),
        findsOneWidget);
  });
  testWidgets(
      'quick status edits separately and a future real plan takes precedence',
      (tester) async {
    var edited = 0;
    await tester.pumpWidget(MaterialApp(
        home: HomeView(
            quickStatus: const QuickStatus(
                freeUntil: '5:00 PM', nextActivity: 'Manual fallback'),
            onEditQuickStatus: () => edited++,
            activityState: ActivityListState(loading: false, activities: [
              ActivitySummary(
                  id: 'real',
                  title: 'Real meeting',
                  location: '',
                  date: '',
                  time: '',
                  confirmed: true,
                  startsAt: DateTime.now().add(const Duration(hours: 2)))
            ]))));
    expect(find.text('5:00 PM'), findsOneWidget);
    expect(find.text('Manual fallback'), findsNothing);
    expect(find.text('Real meeting'), findsWidgets);
    await tester.ensureVisible(find.byTooltip('Edit quick status'));
    await tester.tap(find.byTooltip('Edit quick status'));
    expect(edited, 1);
  });
  testWidgets('quick editor preserves input after save failure and retries',
      (tester) async {
    var attempts = 0;
    String? saved;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: QuickStatusSheet(
      initial: const QuickStatus(freeUntil: '4:00 PM'),
      onSave: (free, next) async {
        attempts++;
        if (attempts == 1) throw StateError('disk');
        saved = next;
      },
    )))));
    await tester.enterText(
        find.widgetWithText(TextField, 'Next activity'), 'Study session');
    await tester.ensureVisible(find.text('Save quick status'));
    await tester.tap(find.text('Save quick status'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to save.'), findsOneWidget);
    expect(find.text('Study session'), findsOneWidget);
    await tester.tap(find.text('Save quick status'));
    await tester.pumpAndSettle();
    expect(saved, 'Study session');
  });
}
