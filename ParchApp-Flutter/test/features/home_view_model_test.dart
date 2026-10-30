import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/activities/domain/entities/activity_summary.dart';
import 'package:parchapp/features/activities/domain/repositories/activity_catalog.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:parchapp/features/groups/domain/entities/active_group.dart';
import 'package:parchapp/features/groups/domain/repositories/active_groups_repository.dart';
import 'package:parchapp/features/home/presentation/view_models/home_view_model.dart';

class Catalog implements ActivityCatalog {
  Future<List<ActivitySummary>> Function() read = () async => [activity];
  @override
  Future<List<ActivitySummary>> listActivities() => read();
}

class Groups implements ActiveGroupsRepository {
  Future<List<ActiveGroup>> Function() read = () async => [];
  @override
  Future<List<ActiveGroup>> getActiveGroups() => read();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Alerts implements AlertsRepository {
  Future<List<AppAlert>> Function() read = () async => [alert];
  @override
  Future<List<AppAlert>> getAlerts() => read();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const activity = ActivitySummary(
    id: 'activity-1',
    title: 'Real plan',
    location: '',
    date: '',
    time: '',
    confirmed: false);
const alert = AppAlert(
    id: 'invitation-1',
    kind: AlertKind.invitation,
    period: AlertPeriod.today,
    title: 'Invitation',
    description: '',
    timeLabel: '12:00');

void main() {
  test('section failure does not hide successful activities and inbox',
      () async {
    final groups = Groups()..read = () async => throw StateError('denied');
    final model =
        HomeViewModel(catalog: Catalog(), groups: groups, alerts: Alerts());
    addTearDown(model.dispose);
    await model.load();
    expect(model.value.activities.activities.single.id, 'activity-1');
    expect(model.value.activities.error, isNull);
    expect(model.value.groups.error, isNotNull);
    expect(model.value.groups.isLoading, isFalse);
    expect(model.value.alerts.unreadCount, 1);
    expect(model.value.profile.error, isNotNull);
  });

  test('failed refresh retains last successful sections with an error',
      () async {
    final catalog = Catalog();
    final alerts = Alerts();
    final model =
        HomeViewModel(catalog: catalog, alerts: alerts, groups: Groups());
    addTearDown(model.dispose);
    await model.load();
    catalog.read = () async => throw StateError('network');
    alerts.read = () async => throw StateError('network');
    await model.load();
    expect(model.value.activities.activities.single, activity);
    expect(model.value.activities.error, isNotNull);
    expect(model.value.alerts.alerts.single, alert);
    expect(model.value.alerts.error, isNotNull);
    catalog.read = () async => [];
    alerts.read = () async => [];
    await model.load();
    expect(model.value.activities.activities, isEmpty);
    expect(model.value.activities.error, isNull);
    expect(model.value.alerts.unreadCount, 0);
    expect(model.value.alerts.error, isNull);
  });

  test('late response from another account cannot replace the current data',
      () async {
    var uid = 'first';
    final first = Completer<List<ActivitySummary>>();
    final catalog = Catalog()..read = () => first.future;
    final model = HomeViewModel(catalog: catalog, currentUserId: () => uid);
    addTearDown(model.dispose);
    final pending = model.load();
    uid = 'second';
    catalog.read = () async => [];
    await model.load();
    first.complete([activity]);
    await pending;
    expect(model.value.activities.activities, isEmpty);
    expect(model.value.activities.error, isNull);
  });

  test('session change without a reload clears previously loaded content',
      () async {
    var uid = 'first';
    final slow = Completer<List<ActiveGroup>>();
    final model = HomeViewModel(
        catalog: Catalog(),
        groups: Groups()..read = () => slow.future,
        currentUserId: () => uid);
    addTearDown(model.dispose);
    final pending = model.load();
    await Future<void>.delayed(Duration.zero);
    expect(model.value.activities.activities, isNotEmpty);
    uid = 'second';
    slow.complete([]);
    await pending;
    expect(model.value.activities.activities, isEmpty);
    expect(model.value.activities.error, contains('Session changed'));
  });

  test('returning to the same UID does not revive an earlier request',
      () async {
    var uid = 'first';
    final stale = Completer<List<ActivitySummary>>();
    final catalog = Catalog()..read = () => stale.future;
    final model = HomeViewModel(catalog: catalog, currentUserId: () => uid);
    addTearDown(model.dispose);
    final pending = model.load();
    uid = 'second';
    catalog.read = () async => [];
    await model.load();
    uid = 'first';
    await model.load();
    stale.complete([activity]);
    await pending;
    expect(model.value.activities.activities, isEmpty);
    expect(model.value.activities.error, isNull);
  });

  test('overlapping refreshes share the pending request and tolerate disposal',
      () async {
    var reads = 0;
    final result = Completer<List<ActivitySummary>>();
    final catalog = Catalog()
      ..read = () {
        reads++;
        return result.future;
      };
    final model = HomeViewModel(catalog: catalog);
    final first = model.load();
    final second = model.load();
    expect(reads, 1);
    model.dispose();
    result.complete([activity]);
    await Future.wait([first, second]);
  });
}
