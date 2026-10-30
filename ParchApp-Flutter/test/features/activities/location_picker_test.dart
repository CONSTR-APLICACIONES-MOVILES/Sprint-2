import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parchapp/features/activities/domain/repositories/places_source.dart';
import 'package:parchapp/features/activities/domain/entities/activity_location.dart';
import 'package:parchapp/features/activities/domain/entities/activity_draft.dart';
import 'package:parchapp/features/activities/presentation/views/location_picker_view.dart';

class TestPlaces implements PlacesSource {
  bool configured = true;
  String? token, detailToken;
  final searches = <String>[];
  Completer<List<PlaceSuggestion>>? delayed;
  @override
  Future<bool> isConfigured() async => configured;
  @override
  Future<List<PlaceSuggestion>> search(
      String query, String session, double latitude, double longitude) async {
    token = session;
    searches.add(query);
    if (query == 'old' && delayed != null) return delayed!.future;
    return [PlaceSuggestion('place-1', 'Library', query)];
  }

  @override
  Future<ActivityLocation> details(String id, String session) async {
    detailToken = session;
    return const ActivityLocation(
        latitude: 4.6,
        longitude: -74.07,
        label: 'Library · Bogotá',
        placeId: 'place-1');
  }

  @override
  Future<void> endSession(String session) async {}
}

void main() {
  test(
      'location metadata is persisted with the draft and mismatched text is rejected',
      () {
    const point = ActivityLocation(
        latitude: 4.6, longitude: -74.07, label: 'Library', placeId: 'place-1');
    final draft = const ActivityDraft(
            groupId: 'g',
            title: 'Plan',
            location: 'Library',
            locationDetails: point)
        .validated();
    expect(draft.publication('request')['fields'],
        containsPair('locationDetails', point.toMap()));
    expect(ActivityLocation.fromMap(point.toMap(), expectedLabel: 'Changed'),
        isNull);
    expect(
        () => const ActivityDraft(
                groupId: 'g',
                title: 'Plan',
                location: 'Changed',
                locationDetails: point)
            .validated(),
        throwsA(anything));
    expect(
        ActivityLocation.fromMap(
            {'latitude': 100, 'longitude': 0, 'label': 'Bad'}),
        isNull);
  });
  testWidgets(
      'search, result, map selection and confirmation return coordinates',
      (tester) async {
    final source = TestPlaces();
    ActivityLocation? selected;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () async {
                  selected = await Navigator.push(
                      context,
                      MaterialPageRoute<ActivityLocation>(
                          builder: (_) => LocationPickerView(
                              source: source,
                              mapBuilder: (center, onPin) => GestureDetector(
                                  onTap: () =>
                                      onPin(const LatLng(4.61, -74.08)),
                                  child: const Text('Test map')))));
                },
                child: const Text('Pick')))));
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lib');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Library · Bogotá'), findsOneWidget);
    await tester.tap(find.text('Use this location'));
    await tester.pumpAndSettle();
    expect(selected!.placeId, 'place-1');
    expect(source.detailToken, source.token);
  });
  testWidgets('an old search response cannot overwrite a newer query',
      (tester) async {
    final source = TestPlaces()..delayed = Completer<List<PlaceSuggestion>>();
    await tester.pumpWidget(MaterialApp(
        home: LocationPickerView(
            source: source, mapBuilder: (_, __) => const Text('Test map'))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    source.delayed!
        .complete([const PlaceSuggestion('old', 'Stale result', 'old')]);
    await tester.pumpAndSettle();
    expect(find.text('Stale result'), findsNothing);
    expect(find.text('Library'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('unconfigured maps keep manual entry as an honest fallback',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: LocationPickerView(source: TestPlaces()..configured = false)));
    await tester.pumpAndSettle();
    expect(find.textContaining('enter the meeting place manually'),
        findsOneWidget);
  });
}
