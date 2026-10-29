import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/core/data/offline_mobile_api.dart';
import 'package:parchapp/core/data/offline_document_codec.dart';
import 'package:parchapp/core/domain/data_freshness.dart';
import 'package:parchapp/shared/widgets/data_freshness_banner.dart';
import 'package:parchapp/app/router/app_extra_codec.dart';
import 'package:parchapp/features/activities/domain/entities/planning_context.dart';
import 'package:parchapp/features/activities/domain/entities/activity_draft.dart';
import 'package:parchapp/features/activities/data/repositories/firebase_study_sessions_repository.dart';
import 'package:parchapp/features/expansions/presentation/views/coordination_insights_view.dart';
import '../features/activities/activity_phase_b_test.dart'
    show RecoverableSource;

class Store implements OfflineStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class Remote implements MobileApi {
  @override
  Future<Map<String, dynamic>> call(
          String name, Map<String, dynamic> input) async =>
      {'alerts': []};
}

void main() {
  test('large cache documents round trip through the native compute worker',
      () async {
    final payload = {
      'cache': {
        for (var i = 0; i < 9; i++)
          '$i': {
            'name': 'getAlerts',
            'data': {
              'alerts': List.generate(
                  110,
                  (j) => {
                        'id': '$j',
                        'title':
                            'A meaningful title with enough text for a large cache'
                      })
            }
          }
      },
      'pending': [
        {
          'name': 'markAlertsRead',
          'input': {
            'ids': ['a']
          }
        }
      ]
    };
    const codec = OfflineDocumentCodec();
    final encoded = await codec.encode(payload);
    expect(encoded.length, greaterThan(32768));
    expect(await codec.decode(encoded), payload);
  });
  test(
      'cache save time survives restart and changes accounts without exposing another cache',
      () async {
    final store = Store(), at = DateTime.utc(2026, 10, 1, 12);
    String? uid = 'one';
    final first = OfflineMobileApi(
        remote: Remote(),
        store: store,
        project: 'test',
        currentUserId: () => uid,
        clock: () => at);
    await first.call('getAlerts', {});
    first.dispose();
    final reopened = OfflineMobileApi(
        remote: Remote(),
        store: store,
        project: 'test',
        currentUserId: () => uid,
        clock: () => at.add(const Duration(hours: 2)));
    addTearDown(reopened.dispose);
    await reopened.setForcedOffline(true);
    final data = await reopened.call('getAlerts', {});
    final freshness = DataFreshness.fromMap(data);
    expect(freshness.cachedAt, at);
    expect(freshness.isStale(at.add(const Duration(hours: 2))), true);
    uid = 'two';
    await expectLater(reopened.call('getAlerts', {}), throwsStateError);
  });
  test(
      'no-slot comparison, router codec and lost acknowledgement preserve attribution',
      () async {
    const comparison = CreationComparison(
        comparisonEvidenceId: 'comparison-1',
        participantIds: ['organizer', 'member'],
        date: '2030-10-02');
    const codec = AppExtraCodec();
    final restored =
        codec.decode(codec.encode(comparison)) as CreationComparison;
    expect(restored.comparisonEvidenceId, comparison.comparisonEvidenceId);
    final draft = ActivityDraft(
        groupId: 'group',
        title: 'Proposal',
        comparison: restored,
        requestId: 'flow');
    final publication = draft.publication('flow');
    expect(publication['measurementVersion'], 1);
    expect(publication['comparisonEvidenceId'], 'comparison-1');
    expect(publication['participantIds'], comparison.participantIds);
    final source = RecoverableSource(),
        repo = FirebaseStudySessionsRepository(source);
    await expectLater(repo.createActivity(draft), throwsA(anything));
    final pending = await repo.pendingPublication();
    expect(pending!.comparison!.comparisonEvidenceId, 'comparison-1');
    expect(pending.measurementVersion, 1);
    expect(await repo.createActivity(pending), 'created-document');
  });
  testWidgets('saved time is shown explicitly for a stale offline snapshot',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DataFreshnessBanner(
                freshness: DataFreshness(
                    offline: true, cachedAt: DateTime.utc(2020, 1, 1, 16))))));
    expect(find.textContaining('1/1/2020 at 11:00'), findsOneWidget);
    expect(find.textContaining('May be out of date'), findsOneWidget);
  });
  testWidgets('insights distinguish empty denominators, read errors and retry',
      (tester) async {
    bool fail = true;
    await tester.pumpWidget(
        MaterialApp(home: CoordinationInsightsView(loadInsight: () async {
      if (fail) throw StateError('network');
      return {
        'compared': {'activities': 0, 'confirmed': 0, 'confirmationRate': null},
        'direct': {'activities': 0, 'confirmed': 0, 'confirmationRate': null},
        'total': 0,
        'known': 0,
        'unknown': 0,
        'coverage': null,
        'comparisonUsage': null,
        'differencePp': null,
        'windowStart': '2026-09-01',
        'windowEnd': '2026-10-01',
        'updatedAt': '2026-10-26',
        'environment': 'test'
      };
    })));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No data'), findsWidgets);
    expect(find.text('0.0%'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
