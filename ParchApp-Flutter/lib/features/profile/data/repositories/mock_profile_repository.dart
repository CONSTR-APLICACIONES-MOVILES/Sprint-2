import '../../domain/entities/profile_user.dart';
import '../../domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  ProfileUser _user = _sample;

  @override
  Future<ProfileUser> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _user;
  }

  @override
  Future<ProfileUser> updateStatus(AvailabilityStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _user = _user.copyWith(status: status);
    return _user;
  }

  @override
  Future<ProfileUser> updateProfile(ProfileUser user) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _user = user;
    return _user;
  }
}

const _sample = ProfileUser(
  id: 'user-001',
  name: 'Alex Valenzuela',
  program: 'Systems and Computer Engineering',
  verified: true,
  semester: 6,
  year: 2026,
  academicLevel: AcademicLevel.undergraduate,
  campus: 'Central Campus',
  university: 'National University',
  studentId: '2021-0492',
  status: AvailabilityStatus.active,
  plansCompleted: 12,
  activeGroups: 5,
  onTimeRate: 94,
);
