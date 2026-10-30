import '../../domain/entities/active_group.dart';
import '../../domain/entities/response_time_estimate.dart';
import '../../domain/entities/weather_forecast.dart';

enum GroupsFilter { all, study, socialLiving, sports }

class ActiveGroupsState {
  final List<ActiveGroup> groups;

  final Map<String, ResponseTimeEstimate> estimates;
  final Map<String, WeatherForecast> weather;
  final GroupsFilter filter;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  ActiveGroupsState({
    List<ActiveGroup> groups = const [],
    this.estimates = const {},
    this.weather = const {},
    this.filter = GroupsFilter.all,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  }) : groups = List.unmodifiable(groups);

  ResponseTimeEstimate? estimateFor(ActiveGroup group) => estimates[group.id];

  WeatherForecast? weatherFor(ActiveGroup group) => weather[group.id];

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
    Map<String, WeatherForecast>? weather,
    GroupsFilter? filter,
    bool? isLoading,
    bool? isUpdating,
    String? error,
  }) =>
      ActiveGroupsState(
        groups: groups ?? this.groups,
        estimates: estimates ?? this.estimates,
        weather: weather ?? this.weather,
        filter: filter ?? this.filter,
        isLoading: isLoading ?? this.isLoading,
        isUpdating: isUpdating ?? this.isUpdating,
        error: error,
      );
}