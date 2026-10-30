import '../entities/active_group.dart';

abstract final class ActivityTiming {
  static const _happening = Duration(hours: 3);
  static const _soon = Duration(hours: 2);

  static String? label(DateTime? startsAt, DateTime now) {
    if (startsAt == null) return null;
    final gap = startsAt.difference(now);
    if (gap.isNegative) return gap > -_happening ? 'Happening now' : null;
    if (gap < const Duration(hours: 1)) {
      return 'In ${gap.inMinutes < 1 ? 1 : gap.inMinutes} min';
    }
    final days = DateTime(startsAt.year, startsAt.month, startsAt.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days == 0) return 'In ${gap.inHours} h';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return 'In $days days';
    return null;
  }

  static bool isSoon(DateTime? startsAt, DateTime now) =>
      startsAt != null &&
      startsAt.difference(now) <= _soon &&
      startsAt.difference(now) > -_happening;

  static List<ActiveGroup> byUpcoming(List<ActiveGroup> groups, DateTime now) {
    bool upcoming(ActiveGroup group) {
      final startsAt = group.activityStartsAt;
      return startsAt != null && startsAt.difference(now) > -_happening;
    }

    final next = groups.where(upcoming).toList()
      ..sort((a, b) => a.activityStartsAt!.compareTo(b.activityStartsAt!));
    return List.unmodifiable([...next, ...groups.where((g) => !upcoming(g))]);
  }
}