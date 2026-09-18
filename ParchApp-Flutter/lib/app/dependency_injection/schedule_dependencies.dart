import 'package:flutter/material.dart';

import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/domain/services/availability_service.dart';
import '../../features/schedule/domain/use_cases/manage_schedule.dart';
import '../../features/schedule/presentation/view_models/schedule_view_model.dart';
import '../../features/schedule/presentation/views/schedule_view.dart';

class ScheduleDependencies {
  final ScheduleRepository repository;

  const ScheduleDependencies({
    required this.repository,
  });

  factory ScheduleDependencies.mock() => ScheduleDependencies(
        repository: MockScheduleRepository(),
      );

  ScheduleViewModel createViewModel() {
    return ScheduleViewModel(
      ManageSchedule(
        repository,
        const AvailabilityService(),
      ),
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
  State<_ScheduleEntry> createState() => _ScheduleEntryState();
}

class _ScheduleEntryState extends State<_ScheduleEntry> {
  late final ScheduleViewModel viewModel =
      widget.dependencies.createViewModel();

  @override
  Widget build(BuildContext context) {
    return ScheduleView(
      viewModel: viewModel,
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }
}
