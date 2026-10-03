import 'package:flutter/material.dart';

import '../../features/schedule/data/adapters/google_calendar_adapter.dart';
import '../../features/schedule/data/data_sources/google_calendar_auth_data_source.dart';
import '../../features/schedule/data/data_sources/google_calendar_data_source.dart';
import '../../features/schedule/data/data_sources/mock_google_calendar_data_source.dart';
import '../../features/schedule/data/repositories/calendar_import_repository_impl.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';

import '../../features/schedule/domain/repositories/calendar_import_repository.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/domain/services/availability_service.dart';
import '../../features/schedule/domain/use_cases/import_google_calendar.dart';
import '../../features/schedule/domain/use_cases/authorize_google_calendar.dart';
import '../../features/schedule/domain/use_cases/manage_schedule.dart';

import '../../features/schedule/presentation/view_models/schedule_view_model.dart';
import '../../features/schedule/presentation/views/schedule_view.dart';

class ScheduleDependencies {
  final ScheduleRepository repository;
  final CalendarImportRepository calendarImportRepository;

  const ScheduleDependencies({
    required this.repository,
    required this.calendarImportRepository,
  });

  factory ScheduleDependencies.mock() {
    final scheduleRepository =
        MockScheduleRepository();

    final GoogleCalendarDataSource calendarDataSource =
        MockGoogleCalendarDataSource();

    final calendarImportRepository =
        CalendarImportRepositoryImpl(
      dataSource: calendarDataSource,
      authDataSource: GoogleCalendarAuthDataSource(),
      adapter: const GoogleCalendarAdapter(),
    );

    return ScheduleDependencies(
      repository: scheduleRepository,
      calendarImportRepository:
          calendarImportRepository,
    );
  }

  ScheduleViewModel createViewModel() {
    return ScheduleViewModel(
      ManageSchedule(
        repository,
        const AvailabilityService(),
      ),
      ImportGoogleCalendar(
        calendarImportRepository,
        repository,
      ),
      authorizeGoogleCalendar: AuthorizeGoogleCalendar(calendarImportRepository),
    );
  }

  Widget route() {
    return _ScheduleEntry(
      dependencies: this,
    );
  }
}

class _ScheduleEntry extends StatefulWidget {
  final ScheduleDependencies dependencies;

  const _ScheduleEntry({
    required this.dependencies,
  });

  @override
  State<_ScheduleEntry> createState() =>
      _ScheduleEntryState();
}

class _ScheduleEntryState
    extends State<_ScheduleEntry> {
  late final ScheduleViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel =
        widget.dependencies.createViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScheduleView(
      viewModel: _viewModel,
    );
  }
}
