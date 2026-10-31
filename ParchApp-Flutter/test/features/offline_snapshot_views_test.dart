import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/features/activities/data/models/activity_model.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_list_view_model.dart';
import 'package:parchapp/features/home/presentation/views/home_view.dart';
import 'package:parchapp/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:parchapp/features/profile/domain/use_cases/manage_profile.dart';
import 'package:parchapp/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:parchapp/features/profile/presentation/views/profile_view.dart';

class SnapshotApi implements MobileApi {
  @override
  Future<Map<String, dynamic>> call(
          String name, Map<String, dynamic> input) async =>
      {
        'id': 'owner',
        'name': 'Saved student',
        'plansCompleted': 2,
        'activeGroups': 1,
        'offline': true,
        'cachedAt': '2020-01-01T16:00:00Z',
      };
}

void main() {
  testWidgets('Profile retains saved content with timestamp and stale warning',
      (tester) async {
    final repository = FirebaseProfileRepository(SnapshotApi());
    final model = ProfileViewModel(ManageProfile(repository));
    await tester.pumpWidget(MaterialApp(home: ProfileView(viewModel: model)));
    await tester.pumpAndSettle();
    expect(find.text('Saved student'), findsOneWidget);
    expect(find.text('Offline'), findsNWidgets(3));
    expect(find.textContaining('May be out of date'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    model.dispose();
  });
  testWidgets(
      'Home renders cached activity and freshness without inventing live status',
      (tester) async {
    final saved = const ActivityModel({
      'id': 'saved-a',
      'title': 'Saved activity',
      'status': 'PROPOSED',
      'offline': true,
      'cachedAt': '2020-01-01T16:00:00Z'
    }).toSummary();
    await tester.pumpWidget(MaterialApp(
        home: HomeView(
            activityState:
                ActivityListState(activities: [saved], loading: false))));
    await tester.scrollUntilVisible(find.text('Saved activity'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Saved activity'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
