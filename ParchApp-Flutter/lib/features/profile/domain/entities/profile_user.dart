import 'profile_preferences.dart';
import '../../../../core/domain/data_freshness.dart';

enum AvailabilityStatus { active, busy, inClass, focused, inTransit, offline }

extension AvailabilityStatusLabel on AvailabilityStatus {
  String get label => switch (this) {
        AvailabilityStatus.active => 'Active',
        AvailabilityStatus.busy => 'Busy',
        AvailabilityStatus.inClass => 'In class',
        AvailabilityStatus.focused => 'Focused',
        AvailabilityStatus.inTransit => 'In transit',
        AvailabilityStatus.offline => 'Offline',
      };
}

enum AcademicLevel { undergraduate, graduate, master, phd }

class ProfileUser {
  final DataFreshness freshness;
  // Campos
  final String id;
  final String name;
  final String program;
  final bool verified;

  final int semester;
  final int year;
  final AcademicLevel academicLevel;
  final bool academicLevelKnown;

  final String campus;
  final String university;
  final String studentId;

  final AvailabilityStatus status;
  final DateTime? statusExpiresAt;
  final ProfilePreferences preferences;
  AvailabilityStatus get effectiveStatus =>
      statusExpiresAt != null && !statusExpiresAt!.isAfter(DateTime.now())
          ? AvailabilityStatus.offline
          : status;

  final int plansCompleted;
  final int activeGroups;
  final int? onTimeRate;

  final String? photoPath;

  // Constructor
  const ProfileUser({
    required this.id,
    required this.name,
    required this.program,
    required this.verified,
    required this.semester,
    required this.year,
    required this.academicLevel,
    this.academicLevelKnown = true,
    required this.campus,
    required this.university,
    required this.studentId,
    required this.status,
    this.statusExpiresAt,
    this.preferences = const ProfilePreferences(),
    required this.plansCompleted,
    required this.activeGroups,
    required this.onTimeRate,
    this.photoPath,
    this.freshness = const DataFreshness(),
  });

  ProfileUser copyWith(
          {String? name,
          String? program,
          int? semester,
          int? year,
          AcademicLevel? academicLevel,
          String? campus,
          String? university,
          AvailabilityStatus? status,
          DateTime? statusExpiresAt,
          ProfilePreferences? preferences,
          String? photoPath}) =>
      ProfileUser(
          id: id,
          freshness: freshness,
          name: name ?? this.name,
          program: program ?? this.program,
          verified: verified,
          semester: semester ?? this.semester,
          year: year ?? this.year,
          academicLevel: academicLevel ?? this.academicLevel,
          academicLevelKnown: academicLevel != null || academicLevelKnown,
          campus: campus ?? this.campus,
          university: university ?? this.university,
          studentId: studentId,
          status: status ?? this.status,
          statusExpiresAt: statusExpiresAt ?? this.statusExpiresAt,
          preferences: preferences ?? this.preferences,
          plansCompleted: plansCompleted,
          activeGroups: activeGroups,
          onTimeRate: onTimeRate,
          photoPath: photoPath ?? this.photoPath);

  String get initials {
    final parts =
        name.trim().split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get statusLabel => switch (effectiveStatus) {
        AvailabilityStatus.active => 'Available now • Ready to hang out',
        AvailabilityStatus.busy => 'Busy • Not available right now',
        AvailabilityStatus.inClass => 'In class',
        AvailabilityStatus.focused => 'Focused',
        AvailabilityStatus.inTransit => 'In transit',
        AvailabilityStatus.offline => 'Offline',
      };

  String get academicLevelLabel => !academicLevelKnown
      ? 'Not set'
      : switch (academicLevel) {
          AcademicLevel.undergraduate => 'Undergraduate',
          AcademicLevel.graduate => 'Graduate',
          AcademicLevel.master => 'Master',
          AcademicLevel.phd => 'PhD',
        };
}
