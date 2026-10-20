import '../../../../core/data/mobile_api.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final MobileApi _api;
  const FirebaseProfileRepository(this._api);

  ProfileUser _user(Map<String, dynamic> data) => ProfileUser(
        id: data['id'] as String,
        name: data['name'] as String,
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
        status: data['status'] == 'busy'
            ? AvailabilityStatus.busy
            : AvailabilityStatus.active,
        plansCompleted: (data['plansCompleted'] as num).toInt(),
        activeGroups: (data['activeGroups'] as num).toInt(),
        onTimeRate: (data['onTimeRate'] as num?)?.toInt(),
        photoPath: data['photoData'] as String?,
      );

  @override
  Future<ProfileUser> getProfile() async =>
      _user(await _api.call('getProfile', {}));

  @override
  Future<ProfileUser> updateStatus(AvailabilityStatus status) async =>
      _user(await _api.call('updateProfile', {
        'fields': {'status': status.name}
      }));

  @override
  Future<ProfileUser> updateProfile(ProfileUser user) async =>
      _user(await _api.call('updateProfile', {
        'fields': {
          'name': user.name.trim(),
          'program': user.program.trim(),
          'semester': user.semester,
          'year': user.year,
          if (user.academicLevelKnown) 'academicLevel': user.academicLevel.name,
          'campus': user.campus.trim(),
          'university': user.university.trim(),
          'studentId': user.studentId,
          'status': user.status.name,
          if (user.photoPath != null) 'photoData': user.photoPath,
        }
      }));
}
