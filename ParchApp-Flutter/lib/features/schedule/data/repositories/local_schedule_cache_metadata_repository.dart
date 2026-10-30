import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/schedule_cache_metadata_repository.dart';

class LocalScheduleCacheMetadataRepository
    implements ScheduleCacheMetadataRepository {
  static const String _keyPrefix = 'schedule_cache_last_updated';

  final FirebaseAuth _auth;

  final SharedPreferencesAsync _preferences;

  LocalScheduleCacheMetadataRepository({
    required FirebaseAuth auth,
    SharedPreferencesAsync? preferences,
  })  : _auth = auth,
        _preferences = preferences ?? SharedPreferencesAsync();

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'A signed-in user is required '
        'to access schedule cache metadata.',
      );
    }

    return user.uid;
  }

  String _key(
    DateTime day,
  ) {
    final normalized = DateTime(
      day.year,
      day.month,
      day.day,
    );

    final dayKey = '${normalized.year}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';

    return '${_keyPrefix}_${_uid}_$dayKey';
  }

  @override
  Future<DateTime?> getLastUpdated(
    DateTime day,
  ) async {
    final value = await _preferences.getString(
      _key(day),
    );

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value,
    );
  }

  @override
  Future<void> markUpdated(
    DateTime day,
    DateTime updatedAt,
  ) async {
    await _preferences.setString(
      _key(day),
      updatedAt.toIso8601String(),
    );
  }
}
