import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/expansions/presentation/views/planning_metrics_view.dart';

void main() {
  testWidgets('missing measurements are not displayed as zero rates',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: PlanningMetricsView(load: () async => {})));
    await tester.pumpAndSettle();
    expect(find.text('No published measurement yet.'), findsWidgets);
    expect(find.text('0%'), findsNothing);
  });
  testWidgets('server failure hides old figures until a successful retry',
      (tester) async {
    var failing = false;
    var reads = 0;
    final sample = <String, dynamic>{
      'failure_or_timeout_pct': 30,
      'attempts': 10,
      'failure': 2,
      'timeout': 1,
      'unresolved': 0,
      'coverage_pct': 100,
      'environment': 'test',
    };
    await tester
        .pumpWidget(MaterialApp(home: PlanningMetricsView(load: () async {
      reads++;
      if (failing) throw StateError('offline');
      return {'bq2_creation_reliability': sample};
    })));
    await tester.pumpAndSettle();
    expect(find.text('Failure or timeout: 30%'), findsOneWidget);
    expect(find.text('TEST DATA'), findsOneWidget);
    failing = true;
    await tester.tap(find.text('Read latest aggregates'));
    await tester.pumpAndSettle();
    expect(find.text('Failure or timeout: 30%'), findsNothing);
    expect(find.textContaining('Unable to load current measurements.'),
        findsOneWidget);
    failing = false;
    await tester.tap(find.text('Read latest aggregates'));
    await tester.pumpAndSettle();
    expect(find.text('Failure or timeout: 30%'), findsOneWidget);
    expect(reads, 3);
  });
}
