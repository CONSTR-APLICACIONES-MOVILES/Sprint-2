import '../../domain/entities/active_group.dart';
import '../../domain/repositories/active_groups_repository.dart';

/// Solo demostración en memoria. Los cambios se pierden al reiniciar la app.
class MockActiveGroupsRepository implements ActiveGroupsRepository {
  final List<ActiveGroup> _groups = List.of(_samples);

  @override
  Future<List<ActiveGroup>> getActiveGroups() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_groups);
  }

  @override
  Future<List<ActiveGroup>> confirmRsvp(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _groups.indexWhere((group) => group.id == id);
    if (index < 0) throw StateError('This group is no longer available.');

    final group = _groups[index];
    final next = group.progressCurrent! + 1;
    final full = next >= group.progressTotal!;
    _groups[index] = group.copyWith(
      statusText: '$next/${group.progressTotal} confirmed for match',
      statusTag: full ? 'Confirmed' : null,
      tone: full ? GroupTone.success : null,
      progressCurrent: next,
    );
    return List.unmodifiable(_groups);
  }

  @override
  Future<List<ActiveGroup>> dropIn(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _groups.indexWhere((group) => group.id == id);
    if (index < 0) throw StateError('This group is no longer available.');

    _groups[index] = _groups[index].copyWith(
      statusText: 'You are in • Common Lounge',
      statusTag: 'Joined',
      tone: GroupTone.success,
    );
    return List.unmodifiable(_groups);
  }
}

const _samples = [
  ActiveGroup(
    id: 'engineering-2026',
    name: 'Engineering 2026',
    category: GroupCategory.study,
    memberCount: 28,
    subtitle: 'Systems & Computer Eng',
    badge: 'Active',
    statusText: '18 available now • 2 study sessions',
    statusTag: 'LIVE',
    tone: GroupTone.info,
    detail: 'Midterm Review Session — Tomorrow 10:00 AM',
    primaryAction: GroupAction.openChat,
    secondaryAction: GroupAction.viewSchedule,
  ),
  ActiveGroup(
    id: 'roomies-main-st',
    name: 'Roomies Main St',
    category: GroupCategory.socialLiving,
    memberCount: 4,
    subtitle: 'Apt 4B',
    badge: 'Shared Flat',
    statusText: '4/4 Synced • All free tonight after 7:30 PM',
    statusTag: 'MATCH!',
    tone: GroupTone.success,
    detail: 'Weekly House Dinner & Grocery Run',
    primaryAction: GroupAction.openChat,
    secondaryAction: GroupAction.roommateSync,
  ),
  ActiveGroup(
    id: 'linear-algebra',
    name: 'Linear Algebra Study Team',
    category: GroupCategory.study,
    memberCount: 6,
    subtitle: 'MATH 224',
    statusText: '3 in Central Library • 3rd Floor',
    statusTag: 'On Campus',
    tone: GroupTone.info,
    detail: 'Exam Practice — Friday 4:00 PM',
    primaryAction: GroupAction.openChat,
    secondaryAction: GroupAction.viewNotes,
  ),
  ActiveGroup(
    id: 'futbol-5',
    name: 'Fútbol 5 & Tercer Tiempo',
    category: GroupCategory.sports,
    memberCount: 12,
    subtitle: 'Intramural League',
    statusText: '3/6 confirmed for match • Fri 7:30 PM',
    statusTag: 'Voting Open',
    tone: GroupTone.warning,
    detail: 'Roster Confirmation',
    progressLabel: 'Roster Confirmation',
    progressCurrent: 3,
    progressTotal: 6,
    primaryAction: GroupAction.voteRsvp,
    secondaryAction: GroupAction.teamChat,
  ),
  ActiveGroup(
    id: 'dorm-floor-3',
    name: 'Dorm Floor 3 Hangouts',
    category: GroupCategory.socialLiving,
    memberCount: 16,
    subtitle: 'North Tower',
    statusText: '5 in Common Lounge',
    statusTag: 'Casual Hangout',
    tone: GroupTone.casual,
    detail: 'Mario Kart & Snacks happening now',
    primaryAction: GroupAction.dropIn,
    secondaryAction: GroupAction.chat,
  ),
];