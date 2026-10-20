import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/home/presentation/views/home_view.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_list_view_model.dart';

void main() {
  testWidgets(
      'production Home displays current identity instead of static Alex',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: HomeView(
            activityState: ActivityListState(loading: false),
            userName: 'Gabriel Pinto',
            userInitials: 'GP')));
    expect(find.text('Hello, Gabriel Pinto! 👋'), findsOneWidget);
    expect(find.text('Hello, Alex! 👋'), findsNothing);
    expect(find.text('GP'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(
        home: HomeView(
            activityState: ActivityListState(loading: false),
            userName: 'Updated student',
            userInitials: 'US')));
    expect(find.text('Hello, Updated student! 👋'), findsOneWidget);
    expect(find.text('Hello, Gabriel Pinto! 👋'), findsNothing);
  });
}
