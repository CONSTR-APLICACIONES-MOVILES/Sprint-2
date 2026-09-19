enum GroupCategory { study, socialLiving, sports }

enum GroupTone { info, success, warning, casual }

enum GroupAction {
  openChat,
  viewSchedule,
  roommateSync,
  viewNotes,
  voteRsvp,
  teamChat,
  dropIn,
  chat
}

class ActiveGroup {
  final String id;
  final String name;
  final GroupCategory category;
  final int memberCount;
  final String subtitle;
  final String? badge;
  final String statusText;
  final String? statusTag;
  final GroupTone tone;
  final String detail;
  final String? progressLabel;
  final int? progressCurrent;
  final int? progressTotal;
  final GroupAction primaryAction;
  final GroupAction secondaryAction;

  const ActiveGroup({
    required this.id,
    required this.name,
    required this.category,
    required this.memberCount,
    required this.subtitle,
    required this.statusText,
    required this.tone,
    required this.detail,
    required this.primaryAction,
    required this.secondaryAction,
    this.badge,
    this.statusTag,
    this.progressLabel,
    this.progressCurrent,
    this.progressTotal,
  });

  ActiveGroup copyWith({
    String? statusText,
    String? statusTag,
    GroupTone? tone,
    String? detail,
    int? progressCurrent,
  }) =>
      ActiveGroup(
        id: id,
        name: name,
        category: category,
        memberCount: memberCount,
        subtitle: subtitle,
        badge: badge,
        statusText: statusText ?? this.statusText,
        statusTag: statusTag ?? this.statusTag,
        tone: tone ?? this.tone,
        detail: detail ?? this.detail,
        progressLabel: progressLabel,
        progressCurrent: progressCurrent ?? this.progressCurrent,
        progressTotal: progressTotal,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
      );

  bool get hasProgress => progressCurrent != null && progressTotal != null;

  double get progressValue =>
      hasProgress && progressTotal! > 0 ? progressCurrent! / progressTotal! : 0;

  String get categoryLabel => switch (category) {
        GroupCategory.study => 'Study Groups',
        GroupCategory.socialLiving => 'Social & Living',
        GroupCategory.sports => 'Sports',
      };

  String get memberLabel => '$memberCount members • $subtitle';
}