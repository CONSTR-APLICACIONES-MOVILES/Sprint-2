import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/welcome/presentation/views/welcome_view.dart';

void main() {
  testWidgets('Welcome screen shows core content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeView()));
    expect(find.text('PARCHAPP'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });
}
