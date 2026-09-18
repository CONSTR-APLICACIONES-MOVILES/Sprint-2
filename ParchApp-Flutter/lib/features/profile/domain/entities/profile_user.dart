enum AvailabilityStatus { active, busy }

enum AcademicLevel { undergraduate, graduate, master, phd }

class ProfileUser {
  // Campos
  final String id;
  final String name;
  final String program;
  final bool verified;

  final int semester;
  final int year;
  final AcademicLevel academicLevel;

  final String campus;
  final String university;
  final String studentId;

  final AvailabilityStatus status;

  final int plansCompleted;
  final int activeGroups;
  final int onTimeRate;

  // Constructor
  const ProfileUser({
    required this.id,
    required this.name,
    required this.program,
    required this.verified,
    required this.semester,
    required this.year,
    required this.academicLevel,
    required this.campus,
    required this.university,
    required this.studentId,
    required this.status,
    required this.plansCompleted,
    required this.activeGroups,
    required this.onTimeRate,
  });

  ProfileUser copyWith(
          {String? name,
          String? program,
          int? semester,
          int? year,
          AcademicLevel? academicLevel,
          String? campus,
          String? university,
          AvailabilityStatus? status}) =>
      ProfileUser(
          id: id,
          name: name ?? this.name,
          program: program ?? this.program,
          verified: verified,
          semester: semester ?? this.semester,
          year: year ?? this.year,
          academicLevel: academicLevel ?? this.academicLevel,
          campus: campus ?? this.campus,
          university: university ?? this.university,
          studentId: studentId,
          status: status ?? this.status,
          plansCompleted: plansCompleted,
          activeGroups: activeGroups,
          onTimeRate: onTimeRate);

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

  String get statusLabel => switch (status) {
        AvailabilityStatus.active => 'Available now • Ready to hang out',
        AvailabilityStatus.busy => 'Busy • Not available right now',
      };

  String get academicLevelLabel => switch (academicLevel) {
        AcademicLevel.undergraduate => 'Undergraduate',
        AcademicLevel.graduate => 'Graduate',
        AcademicLevel.master => 'Master',
        AcademicLevel.phd => 'PhD',
      };
}
