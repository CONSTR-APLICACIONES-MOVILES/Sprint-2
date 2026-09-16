import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/app/app.dart';
import 'package:parchapp/features/welcome/presentation/views/welcome_view.dart';

void main() {
  testWidgets('App opens the welcome screen', (tester) async {
    await tester.pumpWidget(const ParchApp());

    expect(find.byType(WelcomeView), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });
}
