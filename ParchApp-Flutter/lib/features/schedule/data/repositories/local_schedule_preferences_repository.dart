import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/schedule_preferences.dart';
import '../../domain/repositories/schedule_preferences_repository.dart';

class LocalSchedulePreferencesRepository
    implements SchedulePreferencesRepository {
  static const String _keyPrefix =
      'schedule_quick_durations_';

  static const int _minimumMinutes = 5;
  static const int _maximumMinutes = 240;
  static const int _maximumFavorites = 4;

  final FirebaseAuth _auth;
  final SharedPreferencesAsync _preferences;

  LocalSchedulePreferencesRepository({
    required FirebaseAuth auth,
    SharedPreferencesAsync? preferences,
  })  : _auth = auth,
        _preferences =
            preferences ?? SharedPreferencesAsync();

  // ================================================================
  // CURRENT USER
  // ================================================================

  String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'A signed-in user is required '
        'to access schedule preferences.',
      );
    }

    return user.uid;
  }

 
  // LOCAL KEY
  //
  // Each Firebase user gets their own local preference.
  //
  // Example:
  //
  // schedule_quick_durations_abc123
  // schedule_quick_durations_xyz789
  //
 

  String get _storageKey {
    return '$_keyPrefix$_currentUserId';
  }

 

  @override
  Future<SchedulePreferences> getPreferences() async {
    final uid = _currentUserId;
    final key = _storageKey;

    debugPrint(
      'SCHEDULE PREFS LOCAL -> '
      'Loading preferences for $uid',
    );

    final storedValues =
        await _preferences.getStringList(
      key,
    );

  
   

    if (storedValues == null) {
      debugPrint(
        'SCHEDULE PREFS LOCAL -> '
        'No saved preferences. '
        'Using defaults: '
        '${SchedulePreferences.defaultQuickDurationsMinutes}',
      );

      return SchedulePreferences.defaults();
    }

    if (storedValues.isEmpty) {
      debugPrint(
        'SCHEDULE PREFS LOCAL -> '
        'Loaded empty favorites list.',
      );

      return const SchedulePreferences(
        quickDurationsMinutes: [],
      );
    }

    final durations = <int>[];

    for (final value in storedValues) {
      final minutes = int.tryParse(
        value,
      );

      if (minutes == null) {
        continue;
      }

      if (!_isValidDuration(minutes)) {
        continue;
      }

      if (durations.contains(minutes)) {
        continue;
      }

      durations.add(
        minutes,
      );

      if (durations.length ==
          _maximumFavorites) {
        break;
      }
    }

    debugPrint(
      'SCHEDULE PREFS LOCAL -> '
      'Loaded: $durations',
    );

    return SchedulePreferences(
      quickDurationsMinutes: durations,
    );
  }

 

  @override
  Future<void> saveQuickDurations(
    List<int> quickDurationsMinutes,
  ) async {
    _validateQuickDurations(
      quickDurationsMinutes,
    );

    final uid = _currentUserId;
    final key = _storageKey;

    final valuesToStore =
        quickDurationsMinutes
            .map(
              (minutes) =>
                  minutes.toString(),
            )
            .toList();

    debugPrint(
      'SCHEDULE PREFS LOCAL -> '
      'Saving for $uid: '
      '$quickDurationsMinutes',
    );

    await _preferences.setStringList(
      key,
      valuesToStore,
    );

    debugPrint(
      'SCHEDULE PREFS LOCAL -> '
      'Saved successfully for $uid: '
      '$quickDurationsMinutes',
    );
  }

 

  bool _isValidDuration(
    int minutes,
  ) {
    return minutes >= _minimumMinutes &&
        minutes <= _maximumMinutes;
  }

  void _validateQuickDurations(
    List<int> durations,
  ) {
    if (durations.length >
        _maximumFavorites) {
      throw ArgumentError(
        'A maximum of '
        '$_maximumFavorites quick durations '
        'is allowed.',
      );
    }

    if (durations.toSet().length !=
        durations.length) {
      throw ArgumentError(
        'Quick durations cannot '
        'contain duplicates.',
      );
    }

    for (final minutes in durations) {
      if (!_isValidDuration(minutes)) {
        throw ArgumentError(
          'Quick durations must be '
          'between $_minimumMinutes and '
          '$_maximumMinutes minutes.',
        );
      }
    }
  }
}