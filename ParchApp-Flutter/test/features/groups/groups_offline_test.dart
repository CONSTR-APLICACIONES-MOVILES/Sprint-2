import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/groups/data/data_sources/firestore_groups_data_source.dart';
import 'package:parchapp/features/groups/data/repositories/firebase_active_groups_repository.dart';
import 'package:parchapp/features/groups/domain/entities/response_time_estimate.dart';
import 'package:parchapp/features/groups/domain/repositories/response_time_insights_repository.dart';
import 'package:parchapp/features/groups/domain/use_cases/estimate_response_time.dart';
import 'package:parchapp/features/groups/domain/use_cases/manage_active_groups.dart';
import 'package:parchapp/features/groups/presentation/view_models/active_groups_view_model.dart';
import 'package:parchapp/features/groups/presentation/views/active_groups_view.dart';

class _User implements User {
  @override
  String get uid => 'owner';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Auth implements FirebaseAuth {
  @override
  User? get currentUser => _User();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// SDK boundary fakes isolate this test from platform channels and real accounts.
// ignore: subtype_of_sealed_class
class _Doc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  String get id => 'team';
  @override
  Map<String, dynamic> data() => {
        'name': 'Saved group',
        'memberIds': ['owner'],
        'members': [],
        'goingIds': [],
        'maybeIds': []
      };
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Snapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  _Snapshot(this.docs);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// Mutable test fixture for network and permission failures, never production data.
// ignore: subtype_of_sealed_class, must_be_immutable
class _Query implements CollectionReference<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> rows;
  final reads = <Source>[];
  Object? failure;
  _Query(this.rows);
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    reads.add(options?.source ?? Source.serverAndCache);
    if (options?.source == Source.server && failure != null) throw failure!;
    return _Snapshot(rows);
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    if ([#where, #orderBy, #limit].contains(i.memberName)) return this;
    return super.noSuchMethod(i);
  }
}

class _Firestore implements FirebaseFirestore {
  final groups = _Query([_Doc()]), activities = _Query([]);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      path == 'groups' ? groups : activities;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _SlowEstimates implements ResponseTimeInsightsRepository {
  final pending = Completer<List<ResponseTimeEstimate>>();
  @override
  Future<List<ResponseTimeEstimate>> getEstimates() => pending.future;
}

void main() {
  test(
      'offline uses only the saved groups and propagates freshness to the view model',
      () async {
    final db = _Firestore();
    final source =
        FirestoreGroupsDataSource(db, _Auth(), canAttemptRemote: () => false);
    final vm = ActiveGroupsViewModel(
        ManageActiveGroups(FirebaseActiveGroupsRepository(source)));
    await vm.load();
    expect(vm.value.isLoading, false);
    expect(vm.value.groups.single.name, 'Saved group');
    expect(vm.value.freshness.offline, true);
    expect(vm.value.freshness.cachedAt, isNull);
    expect(db.groups.reads, [Source.cache]);
    expect(db.activities.reads, [Source.cache]);
    vm.dispose();
  });
  test('network failure falls back to saved data; permissions do not',
      () async {
    final db = _Firestore()
      ..groups.failure =
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    final source =
        FirestoreGroupsDataSource(db, _Auth(), canAttemptRemote: () => true);
    expect((await source.listGroups()).single['name'], 'Saved group');
    expect(source.freshness.offline, true);
    expect(db.groups.reads, [Source.server, Source.cache]);
    db.groups.reads.clear();
    db.groups.failure =
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    await expectLater(source.listGroups(), throwsA(isA<FirebaseException>()));
    expect(db.groups.reads, [Source.server]);
  });
  testWidgets(
      'saved groups render before optional estimates finish and show the offline cloud',
      (tester) async {
    final source = FirestoreGroupsDataSource(_Firestore(), _Auth(),
        canAttemptRemote: () => false);
    final estimates = _SlowEstimates();
    final vm = ActiveGroupsViewModel(
        ManageActiveGroups(FirebaseActiveGroupsRepository(source)),
        estimate: EstimateResponseTime(estimates));
    await tester.pumpWidget(MaterialApp(home: ActiveGroupsView(viewModel: vm)));
    await tester.pump();
    await tester.pump();
    expect(find.text('Saved group'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    estimates.pending.complete([]);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
  test('without saved groups, loading ends with an explicit offline state',
      () async {
    final db = _Firestore()..groups.rows.clear();
    final vm = ActiveGroupsViewModel(ManageActiveGroups(
        FirebaseActiveGroupsRepository(FirestoreGroupsDataSource(db, _Auth(),
            canAttemptRemote: () => false))));
    await vm.load();
    expect(vm.value.isLoading, false);
    expect(vm.value.freshness.offline, true);
    expect(vm.value.error, contains('No saved groups'));
    vm.dispose();
  });
}
