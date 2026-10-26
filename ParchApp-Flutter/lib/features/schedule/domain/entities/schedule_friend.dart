class ScheduleFriend {
  final String id;
  final String name;
  final String fullName;
  final String initials;

  /// Distance from the current user in meters.
  ///
  /// Null means that distance has not been calculated yet.
  final double? distanceMeters;

  const ScheduleFriend({
    required this.id,
    required this.name,
    required this.fullName,
    required this.initials,
    this.distanceMeters,
  });

  ScheduleFriend copyWith({
    String? id,
    String? name,
    String? fullName,
    String? initials,
    double? distanceMeters,
    bool clearDistance = false,
  }) {
    return ScheduleFriend(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      initials: initials ?? this.initials,
      distanceMeters: clearDistance
          ? null
          : distanceMeters ?? this.distanceMeters,
    );
  }
}