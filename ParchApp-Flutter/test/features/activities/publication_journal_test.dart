import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parchapp/features/activities/data/data_sources/publication_journal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('publication survives storage reload with account and project isolation',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first =
        PublicationJournal(preferences, project: 'demo-parchapp', uid: 'alex');
    final data = <String, dynamic>{
      'requestId': 'request-1',
      'groupId': 'group',
      'fields': {'title': 'Reviewed publication'},
      'participantIds': ['alex', 'camila']
    };
    await first.write(data);
    await preferences.reload();
    final restored = PublicationJournal(await SharedPreferences.getInstance(),
        project: 'demo-parchapp', uid: 'alex');
    expect(restored.read(), data);
    expect(
        PublicationJournal(preferences, project: 'demo-parchapp', uid: 'camila')
            .read(),
        isNull);
    expect(
        PublicationJournal(preferences, project: 'other', uid: 'alex').read(),
        isNull);
    await restored.write(data);
    await expectLater(
        restored.write({...data, 'requestId': 'request-2'}), throwsStateError);
    await expectLater(restored.write({...data, 'groupId': 'another-group'}),
        throwsStateError);
    expect(restored.read(), data);
    await restored.clear();
    await preferences.reload();
    expect(restored.read(), isNull);
  });
}
