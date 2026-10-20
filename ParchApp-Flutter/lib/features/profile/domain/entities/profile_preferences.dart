class ProfilePreferences {
  final String statusVisibility, scheduleVisibility;
  final List<String> closeFriendIds;
  final bool invitationBadges;
  const ProfilePreferences(
      {this.statusVisibility = 'groups',
      this.scheduleVisibility = 'groups',
      this.closeFriendIds = const [],
      this.invitationBadges = true});
  factory ProfilePreferences.fromMap(Map<String, dynamic> map) =>
      ProfilePreferences(
          statusVisibility: map['statusVisibility'] ?? 'groups',
          scheduleVisibility: map['scheduleVisibility'] ?? 'groups',
          closeFriendIds: List<String>.from(map['closeFriendIds'] ?? []),
          invitationBadges: map['invitationBadges'] != false);
  Map<String, dynamic> toMap() => {
        'statusVisibility': statusVisibility,
        'scheduleVisibility': scheduleVisibility,
        'closeFriendIds': closeFriendIds,
        'invitationBadges': invitationBadges
      };
}
