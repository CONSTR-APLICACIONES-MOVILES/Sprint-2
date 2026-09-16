import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/alerts/data/repositories/mock_alerts_repository.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/domain/use_cases/manage_alerts.dart';
import 'package:parchapp/features/alerts/presentation/view_models/alerts_state.dart';
import 'package:parchapp/features/alerts/presentation/view_models/alerts_view_model.dart';

class _ControlledRepository extends MockAlertsRepository {
  bool failLoad = false;
  bool failUpdate = false;
  Completer<List<AppAlert>>? pending;
  @override
  Future<List<AppAlert>> getAlerts() async {
    if (failLoad) throw Exception('offline');
    if (pending != null) return pending!.future;
    return super.getAlerts();
  }

  @override
  Future<List<AppAlert>> markAllRead() async {
    if (failUpdate) throw Exception('offline');
    return super.markAllRead();
  }
}

void main() {
  late _ControlledRepository repository;
  late AlertsViewModel model;
  setUp(() {
    repository = _ControlledRepository();
    model = AlertsViewModel(ManageAlerts(repository));
  });
  tearDown(() => model.dispose());

  test('load exposes four today, three earlier and actual unread count',
      () async {
    final request = model.load();
    expect(model.value.isLoading, isTrue);
    await request;
    expect(model.value.alerts.length, 7);
    expect(model.value.unreadCount, 4);
    expect(
        model.value.visibleAlerts
            .where((a) => a.period == AlertPeriod.today)
            .length,
        4);
    expect(model.value.isLoading, isFalse);
    expect(() => model.value.alerts.clear(), throwsUnsupportedError);
  });

  test('search composes with category filters and can be cleared', () async {
    await model.load();
    model.setFilter(AlertsFilter.schedule);
    expect(model.value.visibleAlerts.length, 2);
    model.search('  SARAH  ');
    expect(model.value.visibleAlerts.single.id, 'overlap');
    model.setFilter(AlertsFilter.groups);
    expect(model.value.visibleAlerts, isEmpty);
    model.clearFilters();
    expect(model.value.visibleAlerts.length, 7);
  });

  test('mark read applies to all alerts even with an active filter', () async {
    await model.load();
    model.setFilter(AlertsFilter.friends);
    expect(await model.markAllRead(), isTrue);
    expect(model.value.unreadCount, 0);
    model.setFilter(AlertsFilter.unread);
    expect(model.value.visibleAlerts, isEmpty);
    expect((await repository.getAlerts()).every((a) => a.isRead), isTrue);
  });

  test('accept removes pending request and survives a new ViewModel', () async {
    await model.load();
    final request = model.value.alerts.firstWhere((a) => a.id == 'friend');
    expect(await model.respond(request, AlertResponse.accepted), isTrue);
    expect(model.value.visibleAlerts.any((a) => a.id == 'friend'), isFalse);
    expect(model.value.unreadCount, 3);
    final reopened = AlertsViewModel(ManageAlerts(repository));
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.value.visibleAlerts.any((a) => a.id == 'friend'), isFalse);
  });

  test('use case rejects actions that do not belong to the alert', () async {
    final useCase = ManageAlerts(repository);
    final overlap = (await useCase.load()).first;
    expect(
        () => useCase.respond(overlap, AlertResponse.joined), throwsStateError);
    expect((await repository.getAlerts()).first.isResolved, isFalse);
  });

  test('failed load is recoverable and failed update preserves unread state',
      () async {
    repository.failLoad = true;
    await model.load();
    expect(model.value.error, isNotNull);
    expect(model.value.isLoading, isFalse);
    repository.failLoad = false;
    await model.load();
    expect(model.value.error, isNull);
    repository.failUpdate = true;
    expect(await model.markAllRead(), isFalse);
    expect(model.value.unreadCount, 4);
    expect(model.value.isUpdating, isFalse);
  });

  test('late completion after disposal does not notify listeners', () async {
    final pendingRepo = _ControlledRepository()
      ..pending = Completer<List<AppAlert>>();
    final temporary = AlertsViewModel(ManageAlerts(pendingRepo));
    var notifications = 0;
    temporary.addListener(() => notifications++);
    final request = temporary.load();
    temporary.dispose();
    pendingRepo.pending!.complete([]);
    await request;
    expect(notifications, 1);
  });
}
