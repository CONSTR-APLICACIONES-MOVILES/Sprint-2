import '../../domain/repositories/presence_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/profile_load_failure.dart';
import '../../domain/entities/profile_preferences.dart';
import '../../../../core/data/mobile_api.dart';
import '../../../../core/domain/data_freshness.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/repositories/profile_repository.dart';

class FirebaseProfileRepository
    implements ProfileRepository, PresenceRepository {
  final MobileApi _api;
  const FirebaseProfileRepository(this._api);

  ProfileUser _user(Map<String, dynamic> data) => ProfileUser(
        freshness: DataFreshness.fromMap(data),
        id: data['id'] as String,
        name: data['name'] as String,
        username: data['username'] as String?,
        program: data['program'] as String? ?? '',
        verified: data['verified'] == true,
        semester: (data['semester'] as num?)?.toInt() ?? 0,
        year: (data['year'] as num?)?.toInt() ?? 0,
        academicLevel: AcademicLevel.values.firstWhere(
            (level) => level.name == data['academicLevel'],
            orElse: () => AcademicLevel.undergraduate),
        academicLevelKnown: data['academicLevel'] != null,
        campus: data['campus'] as String? ?? '',
        university: data['university'] as String? ?? '',
        studentId: data['studentId'] as String? ?? '',
        status: AvailabilityStatus.values.firstWhere(
            (s) => s.name == data['status'],
            orElse: () => AvailabilityStatus.offline),
        statusExpiresAt: DateTime.tryParse(data['statusExpiresAt'] ?? ''),
        preferences: ProfilePreferences.fromMap(
            Map<String, dynamic>.from(data['preferences'] ?? {})),
        plansCompleted: (data['plansCompleted'] as num).toInt(),
        activeGroups: (data['activeGroups'] as num).toInt(),
        onTimeRate: (data['onTimeRate'] as num?)?.toInt(),
        photoPath: data['photoData'] as String?,
      );

  @override
  Future<ProfileUser> updatePresence(
      AvailabilityStatus status, DateTime expiresAt, String visibility,
      {String? ownerId}) async {
    return _user(await _api.call('updatePresence', {
      if (ownerId != null) 'clientUserId': ownerId,
      'status': status.name,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'visibility': visibility
    }));
  }

  @override
  Future<ProfileUser> updatePreferences(ProfilePreferences preferences,
      {String? ownerId}) async {
    return _user(await _api.call('updatePreferences', {
      'preferences': preferences.toMap(),
      if (ownerId != null) 'clientUserId': ownerId
    }));
  }

  @override
  Future<List<Map<String, dynamic>>> getPeers() async =>
      ((await _api.call('getCommunityPeers', {}))['peers'] as List)
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
  @override
  Future<ProfileUser> getProfile() async {
    try {
      return _user(await _api.call('getProfile', {}));
    } on FirebaseFunctionsException catch (error) {
      throw ProfileLoadFailure(switch (error.code) {
        'unauthenticated' =>
          'Your session could not be verified. Sign out and sign in again.',
        'permission-denied' =>
          'The backend denied profile access. The team must check the deployed function permissions.',
        'not-found' ||
        'unimplemented' =>
          'The profile service is not deployed in this Firebase project.',
        'unavailable' ||
        'deadline-exceeded' =>
          'The profile service is unreachable. Check your connection and retry.',
        _ => 'Unable to load your profile (${error.code}). Please retry.',
      });
    }
  }

  @override
  Future<ProfileUser> updateStatus(AvailabilityStatus status) async =>
      _user(await _api.call('updateProfile', {
        'fields': {'status': status.name}
      }));

  @override
  Future<ProfileUser> updateProfile(ProfileUser user) async =>
      _user(await _api.call('updateProfile', {
        'clientUserId': user.id,
        'fields': {
          'name': user.name.trim(),
          'program': user.program.trim(),
          'semester': user.semester,
          'year': user.year,
          if (user.academicLevelKnown) 'academicLevel': user.academicLevel.name,
          'campus': user.campus.trim(),
          'university': user.university.trim(),
          'studentId': user.studentId,
          if (user.photoPath != null) 'photoData': user.photoPath,
        }
      }));
}
