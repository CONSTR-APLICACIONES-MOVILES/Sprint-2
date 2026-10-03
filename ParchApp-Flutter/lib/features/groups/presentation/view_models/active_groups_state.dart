import '../../domain/entities/active_group.dart';
import '../../domain/entities/response_time_estimate.dart';

enum GroupsFilter { all, study, socialLiving, sports }

class ActiveGroupsState {
  final List<ActiveGroup> groups;

  final Map<String, ResponseTimeEstimate> estimates;
  final GroupsFilter filter;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  ActiveGroupsState({
    List<ActiveGroup> groups = const [],
    this.estimates = const {},
    this.filter = GroupsFilter.all,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  }) : groups = List.unmodifiable(groups);

  ResponseTimeEstimate? estimateFor(ActiveGroup group) => estimates[group.id];

  List<ActiveGroup> get visibleGroups => switch (filter) {
        GroupsFilter.all => groups,
        GroupsFilter.study =>
          groups.where((g) => g.category == GroupCategory.study).toList(),
        GroupsFilter.socialLiving =>
          groups.where((g) => g.category == GroupCategory.socialLiving).toList(),
        GroupsFilter.sports =>
          groups.where((g) => g.category == GroupCategory.sports).toList(),
      };

  int countFor(GroupsFilter value) => switch (value) {
        GroupsFilter.all => groups.length,
        GroupsFilter.study =>
          groups.where((g) => g.category == GroupCategory.study).length,
        GroupsFilter.socialLiving =>
          groups.where((g) => g.category == GroupCategory.socialLiving).length,
        GroupsFilter.sports =>
          groups.where((g) => g.category == GroupCategory.sports).length,
      };

  String labelFor(GroupsFilter value) => switch (value) {
        GroupsFilter.all => 'All',
        GroupsFilter.study => 'Study Groups',
        GroupsFilter.socialLiving => 'Social & Living',
        GroupsFilter.sports => 'Sports',
      };

  ActiveGroupsState copyWith({
    List<ActiveGroup>? groups,
    Map<String, ResponseTimeEstimate>? estimates,
    GroupsFilter? filter,
    bool? isLoading,
    bool? isUpdating,
    String? error,
  }) =>
      ActiveGroupsState(
        groups: groups ?? this.groups,
        estimates: estimates ?? this.estimates,
        filter: filter ?? this.filter,
        isLoading: isLoading ?? this.isLoading,
        isUpdating: isUpdating ?? this.isUpdating,
        error: error,
      );
}