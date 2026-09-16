import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/activities/data/repositories/mock_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/entities/study_session.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/study_session_view_model.dart';

class ControlledSessions extends MockStudySessionsRepository {
  bool failLoad = false;
  bool failSave = false;
  int saves = 0;
  Completer<StudySession>? pendingSave;
  @override
  Future<StudySession?> getById(String id) async {
    if (failLoad) throw Exception('transport failure');
    return super.getById(id);
  }

  @override
  Future<StudySession> save(StudySession session) async {
    saves++;
    if (failSave) throw Exception('transport failure');
    if (pendingSave != null) await pendingSave!.future;
    return super.save(session);
  }
}

void main() {
  late ControlledSessions repository;
  late ManageStudySession actions;
  late StudySessionViewModel model;
  setUp(() {
    repository = ControlledSessions();
    actions = ManageStudySession(repository);
    model = StudySessionViewModel(actions, 'linear-algebra');
  });
  tearDown(() => model.dispose());

  test('load exposes immutable topics, participants and resources', () async {
    await model.load();
    expect(model.value.status, SessionLoadStatus.ready);
    final session = model.value.session!;
    expect(session.participants.length, 4);
    expect(() => session.topics.clear(), throwsUnsupportedError);
    expect(() => session.participants.clear(), throwsUnsupportedError);
    expect(() => session.resources.clear(), throwsUnsupportedError);
  });

  test('unknown ID is not replaced by the sample session', () async {
    final missing = StudySessionViewModel(actions, 'missing');
    addTearDown(missing.dispose);
    await missing.load();
    expect(missing.value.status, SessionLoadStatus.notFound);
    expect(missing.value.session, isNull);
  });

  test('load failure is recoverable and hides transport errors', () async {
    repository.failLoad = true;
    await model.load();
    expect(model.value.status, SessionLoadStatus.error);
    expect(model.value.error, isNot(contains('transport')));
    repository.failLoad = false;
    await model.load();
    expect(model.value.status, SessionLoadStatus.ready);
    expect(model.value.error, isNull);
  });

  test('topic progress persists across ViewModels and can be undone', () async {
    await model.load();
    expect(await model.toggleTopic('eigenvalues'), isTrue);
    final reopened = StudySessionViewModel(actions, 'linear-algebra');
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.value.session!.topics.first.completed, isTrue);
    await reopened.toggleTopic('eigenvalues');
    expect((await repository.getById('linear-algebra'))!.topics.first.completed,
        isFalse);
  });

  test('editing saves trimmed values and dates without losing progress',
      () async {
    await model.load();
    await model.toggleTopic('eigenvalues');
    final start = DateTime(2026, 11, 1, 10);
    final end = DateTime(2026, 11, 1, 12);
    expect(
        await model.update(
            title: ' New title ',
            room: ' Room 5 ',
            startsAt: start,
            endsAt: end),
        isTrue);
    final stored = (await repository.getById('linear-algebra'))!;
    expect(stored.title, 'New title');
    expect(stored.room, 'Room 5');
    expect(stored.startsAt, start);
    expect(stored.endsAt, end);
    expect(stored.topics.first.completed, isTrue);
  });

  for (final input in [
    ('', 'Room', 2),
    ('Title', ' ', 2),
    ('Title', 'Room', 0),
    ('Title', 'Room', -1)
  ]) {
    test('invalid edit $input cannot change repository', () async {
      await model.load();
      final before = model.value.session!;
      expect(
          await model.update(
              title: input.$1,
              room: input.$2,
              startsAt: before.startsAt,
              endsAt: before.startsAt.add(Duration(hours: input.$3))),
          isFalse);
      expect(repository.saves, 0);
      expect(model.value.session, same(before));
      expect(model.value.error, isNotNull);
    });
  }

  test('cancel persists and domain rejects subsequent modifications', () async {
    await model.load();
    expect(await model.cancel(), isTrue);
    expect((await actions.load('linear-algebra'))!.cancelled, isTrue);
    await expectLater(actions.toggleTopic('linear-algebra', 'eigenvalues'),
        throwsA(isA<SessionFailure>()));
    final session = model.value.session!;
    await expectLater(
        actions.update(session.id,
            title: 'Changed',
            room: 'Room',
            startsAt: session.startsAt,
            endsAt: session.endsAt),
        throwsA(isA<SessionFailure>()));
    expect(repository.saves, 1);
  });

  test('unknown topic cannot modify session', () async {
    await expectLater(actions.toggleTopic('linear-algebra', 'missing'),
        throwsA(isA<SessionFailure>()));
    expect(repository.saves, 0);
  });

  test('failed save preserves prior state and retry succeeds', () async {
    await model.load();
    final before = model.value.session;
    repository.failSave = true;
    expect(await model.toggleTopic('eigenvalues'), isFalse);
    expect(model.value.session, same(before));
    expect(model.value.saving, isFalse);
    repository.failSave = false;
    expect(await model.toggleTopic('eigenvalues'), isTrue);
    expect(model.value.error, isNull);
  });

  test('duplicate writes are ignored and disposal suppresses late emission',
      () async {
    final temporary = StudySessionViewModel(actions, 'linear-algebra');
    await temporary.load();
    repository.pendingSave = Completer<StudySession>();
    var notifications = 0;
    temporary.addListener(() => notifications++);
    final first = temporary.toggleTopic('eigenvalues');
    expect(await temporary.cancel(), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(repository.saves, 1);
    temporary.dispose();
    repository.pendingSave!.complete(
        model.value.session ?? (await repository.getById('linear-algebra'))!);
    expect(await first, isFalse);
    expect(notifications, 1);
  });
}
