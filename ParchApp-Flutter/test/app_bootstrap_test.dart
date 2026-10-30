import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/main.dart';

void main() {
  testWidgets('startup draws progress while initialization waits, only once',
      (tester) async {
    final ready = Completer<Widget>();
    var calls = 0;
    await tester.pumpWidget(AppBootstrap(initialize: () {
      calls++;
      return ready.future;
    }));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    ready.complete(const MaterialApp(home: Text('Ready')));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('initialization error shows a recoverable message',
      (tester) async {
    await tester.pumpWidget(
        AppBootstrap(initialize: () async => throw StateError('test')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to start ParchApp'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
