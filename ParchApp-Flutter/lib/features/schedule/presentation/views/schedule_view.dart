import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_navigation_bar.dart';
import '../../domain/entities/common_slot.dart';
import '../../domain/entities/schedule_block.dart';
import '../../domain/entities/schedule_friend.dart';
import '../view_models/schedule_state.dart';
import '../view_models/schedule_view_model.dart';

class ScheduleView extends StatefulWidget {
  final ScheduleViewModel viewModel;

  const ScheduleView({
    super.key,
    required this.viewModel,
  });

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  static const double _pixelsPerMinute = 1;
  static const int _startHour = 8;
  static const int _endHour = 18;

  static const double _timelineHeight =
      (_endHour - _startHour) * 60 * _pixelsPerMinute;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void didUpdateWidget(covariant ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.viewModel != widget.viewModel) {
      widget.viewModel.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScheduleState>(
      valueListenable: widget.viewModel,
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FC),
          appBar: _buildAppBar(context),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildFriendBar(context, state),
                _buildCalendarImportBar(state),
                _buildDurationBar(state),
                _buildWeekSelector(state),

                if (state.status == ScheduleLoadStatus.loading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                  ),

                if (state.status == ScheduleLoadStatus.error)
                  Expanded(
                    child: _buildErrorState(state),
                  )
                else
                  Expanded(
                    child: _buildScheduleContent(
                      context,
                      state,
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: state.status == ScheduleLoadStatus.ready
              ? FloatingActionButton(
                  tooltip: 'Plan activity',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => _planActivity(
                    context,
                    state,
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: const ParchNavigationBar(
            selectedIndex: 2,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/images/parchapp_logo.png',
            width: 32,
            height: 32,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.people_alt_rounded,
                color: AppColors.primary,
                size: 30,
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'ParchApp',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Schedule search will be connected later.',
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
        ),
        IconButton(
          tooltip: 'Alerts',
          onPressed: () => context.push(
            AppRoutes.alerts,
          ),
          icon: const Badge(
            smallSize: 7,
            backgroundColor: AppColors.error,
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Profile will be connected later.',
                ),
              ),
            );
          },
          icon: const CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFriendBar(
    BuildContext context,
    ScheduleState state,
  ) {
    final selectedFriends = state.friends.where(
      (friend) => state.selectedFriendIds.contains(
        friend.id,
      ),
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const _MeChip(),

                  for (final friend in selectedFriends) ...[
                    const SizedBox(width: 6),
                    _FriendChip(
                      friend: friend,
                      onRemove: () {
                        widget.viewModel.toggleFriend(
                          friend.id,
                        );
                      },
                    ),
                  ],

                  const SizedBox(width: 6),

                  ActionChip(
                    avatar: const Icon(
                      Icons.person_add_alt_1,
                      size: 17,
                    ),
                    label: const Text(
                      'Add friends',
                    ),
                    onPressed: () => _showFriendPicker(
                      context,
                    ),
                    side: const BorderSide(
                      color: Color(0xFF9CB8E9),
                    ),
                    backgroundColor:
                        const Color(0xFFF2F6FF),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: state.selectedFriendIds.isEmpty
                  ? const Color(0xFFE9EEF7)
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.compare_arrows_rounded,
                  size: 17,
                  color: state.selectedFriendIds.isEmpty
                      ? AppColors.textSecondary
                      : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Comparing (${state.selectedFriendIds.length + 1})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: state.selectedFriendIds.isEmpty
                        ? AppColors.textSecondary
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarImportBar(
  ScheduleState state,
) {
  final importing =
      state.calendarImportStatus ==
          CalendarImportStatus.importing;

  final imported =
      state.calendarImportStatus ==
          CalendarImportStatus.imported;

  final hasError =
      state.calendarImportStatus ==
          CalendarImportStatus.error;

  return Container(
    width: double.infinity,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(
      14,
      4,
      12,
      8,
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDCE3EF),
        ),
      ),
      child: Row(
        children: [
          // Google Calendar icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 10),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Google Calendar',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _calendarImportSubtitle(state),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasError
                        ? AppColors.error
                        : imported
                            ? AppColors.success
                            : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Import button
          SizedBox(
            width: 105,
            height: 34,
            child: FilledButton.icon(
              onPressed: importing || imported
                  ? null
                  : widget
                      .viewModel
                      .importGoogleCalendar,

              style: FilledButton.styleFrom(
                backgroundColor:
                    AppColors.primary,

                foregroundColor:
                    Colors.white,

                disabledBackgroundColor:
                    imported
                        ? const Color(0xFFE8F8F0)
                        : const Color(0xFFE9EEF7),

                disabledForegroundColor:
                    imported
                        ? AppColors.success
                        : AppColors.textSecondary,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                ),

                minimumSize: const Size(
                  105,
                  34,
                ),

                maximumSize: const Size(
                  105,
                  34,
                ),

                tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                ),
              ),

              icon: importing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      imported
                          ? Icons.check_rounded
                          : Icons
                              .file_download_outlined,
                      size: 17,
                    ),

              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  importing
                      ? 'Importing'
                      : imported
                          ? 'Imported'
                          : hasError
                              ? 'Try again'
                              : 'Import',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  String _calendarImportSubtitle(
    ScheduleState state,
  ) {
    switch (state.calendarImportStatus) {
      case CalendarImportStatus.importing:
        return 'Importing your calendar events...';
      case CalendarImportStatus.imported:
        return state.calendarImportMessage ??
            'Calendar events imported.';
      case CalendarImportStatus.error:
        return state.calendarImportMessage ??
            'Could not import calendar.';
      case CalendarImportStatus.idle:
        return 'Import your events into My Schedule.';
    }
  }

  Widget _buildDurationBar(
    ScheduleState state,
  ) {
    final quickDurations = <Duration>[
      const Duration(minutes: 30),
      const Duration(minutes: 45),
      const Duration(hours: 1),
      const Duration(hours: 2),
    ];

    final currentHours =
        state.meetingDuration.inHours;

    final currentMinutes =
        state.meetingDuration.inMinutes % 60;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        14,
        6,
        12,
        6,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 18,
            color: AppColors.primary,
          ),

          const SizedBox(width: 5),

          const Text(
            'Duration:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...quickDurations.map(
                    (duration) {
                      final selected =
                          state.meetingDuration ==
                              duration;

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          right: 6,
                        ),
                        child: ChoiceChip(
                          showCheckmark: false,
                          selected: selected,
                          selectedColor:
                              AppColors.primary,
                          backgroundColor:
                              const Color(
                            0xFFE9EEF7,
                          ),
                          side: BorderSide.none,
                          label: Text(
                            _durationLabel(
                              duration,
                            ),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors
                                      .textSecondary,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          onSelected: (_) {
                            widget.viewModel
                                .setDuration(
                              duration,
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 4),

                  _buildDurationStepper(
                    hours: currentHours,
                    minutes: currentMinutes,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildDurationStepper({
  required int hours,
  required int minutes,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FD),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFD8E1EF),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // HOURS
        _buildHorizontalStepper(
          value: hours,

          onDecrease: () {
            if (hours == 0) {
              return;
            }

            _updateCustomDuration(
              hours: hours - 1,
              minutes: minutes,
            );
          },

          onIncrease: () {
            _updateCustomDuration(
              hours: hours + 1,
              minutes: minutes,
            );
          },

          onSubmitted: (newHours) {
            var safeHours = newHours;

            if (safeHours < 0) {
              safeHours = 0;
            }

            if (safeHours > 12) {
              safeHours = 12;
            }

            _updateCustomDuration(
              hours: safeHours,
              minutes: minutes,
            );
          },
        ),

        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 5,
          ),
          child: Text(
            ':',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        // MINUTES
        _buildHorizontalStepper(
          value: minutes,
          twoDigits: true,

          onDecrease: () {
            if (minutes == 0) {
              if (hours == 0) {
                return;
              }

              _updateCustomDuration(
                hours: hours - 1,
                minutes: 59,
              );

              return;
            }

            _updateCustomDuration(
              hours: hours,
              minutes: minutes - 1,
            );
          },

          onIncrease: () {
            if (minutes == 59) {
              _updateCustomDuration(
                hours: hours + 1,
                minutes: 0,
              );

              return;
            }

            _updateCustomDuration(
              hours: hours,
              minutes: minutes + 1,
            );
          },

          onSubmitted: (newMinutes) {
            var safeMinutes = newMinutes;

            if (safeMinutes < 0) {
              safeMinutes = 0;
            }

            if (safeMinutes > 59) {
              safeMinutes = 59;
            }

            _updateCustomDuration(
              hours: hours,
              minutes: safeMinutes,
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildHorizontalStepper({
  required int value,
  required VoidCallback onDecrease,
  required VoidCallback onIncrease,
  required ValueChanged<int> onSubmitted,
  bool twoDigits = false,
}) {
  final controller = TextEditingController(
    text: twoDigits
        ? value.toString().padLeft(2, '0')
        : value.toString(),
  );

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onDecrease,
        child: const Padding(
          padding: EdgeInsets.all(3),
          child: Icon(
            Icons.chevron_left_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
      ),

      SizedBox(
        width: 32,
        height: 30,
        child: TextField(
          controller: controller,

          textAlign: TextAlign.center,

          keyboardType: TextInputType.number,

          textInputAction: TextInputAction.done,

          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),

          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 2,
            ),
            border: InputBorder.none,
          ),

          onSubmitted: (text) {
            final parsed = int.tryParse(text);

            if (parsed == null) {
              return;
            }

            onSubmitted(parsed);
          },

          onTapOutside: (_) {
            FocusScope.of(context).unfocus();

            final parsed =
                int.tryParse(controller.text);

            if (parsed != null) {
              onSubmitted(parsed);
            }
          },
        ),
      ),

      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onIncrease,
        child: const Padding(
          padding: EdgeInsets.all(3),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
      ),
    ],
  );
}


void _updateCustomDuration({
  required int hours,
  required int minutes,
}) {
  if (hours < 0) {
    hours = 0;
  }

  if (hours > 12) {
    hours = 12;
  }

  if (minutes < 0) {
    minutes = 0;
  }

  if (minutes > 59) {
    minutes = 59;
  }

  if (hours == 0 &&
      minutes == 0) {
    return;
  }

  widget.viewModel.setDuration(
    Duration(
      hours: hours,
      minutes: minutes,
    ),
  );
}

  Widget _buildWeekSelector(
    ScheduleState state,
  ) {
    final monday = _startOfWeek(
      state.selectedDay,
    );

    final sunday = monday.add(
      const Duration(days: 6),
    );

    // ParchApp keeps its Monday-Friday visual layout.
    final days = List.generate(
      5,
      (index) => monday.add(
        Duration(days: index),
      ),
    );

    // We only allow navigation inside 2026.
    final previousWeekDay =
        state.selectedDay.subtract(
      const Duration(days: 7),
    );

    final nextWeekDay =
        state.selectedDay.add(
      const Duration(days: 7),
    );

    final canGoPrevious =
        previousWeekDay.year == 2026;

    final canGoNext =
        nextWeekDay.year == 2026;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        9,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Previous week
              IconButton(
                tooltip: 'Previous week',
                onPressed: canGoPrevious
                    ? () {
                        _changeWeek(
                          state,
                          -1,
                        );
                      }
                    : null,
                visualDensity:
                    VisualDensity.compact,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 24,
                ),
                color: AppColors.textPrimary,
                disabledColor:
                    AppColors.textSecondary
                        .withValues(
                  alpha: 0.35,
                ),
              ),

              // Week text.
              // Tapping it also opens the calendar.
              Expanded(
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(10),
                  onTap: () {
                    _openCalendarPicker(
                      state,
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 4,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SELECTED WEEK',
                          style: TextStyle(
                            color: AppColors
                                .textSecondary,
                            fontSize: 8,
                            letterSpacing: 0.8,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _weekRangeLabel(
                            monday,
                            sunday,
                          ),
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: AppColors
                                .textPrimary,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Next week
              IconButton(
                tooltip: 'Next week',
                onPressed: canGoNext
                    ? () {
                        _changeWeek(
                          state,
                          1,
                        );
                      }
                    : null,
                visualDensity:
                    VisualDensity.compact,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                ),
                color: AppColors.textPrimary,
                disabledColor:
                    AppColors.textSecondary
                        .withValues(
                  alpha: 0.35,
                ),
              ),

              const SizedBox(width: 2),

              // Open monthly calendar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF1FF),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: IconButton(
                  tooltip: 'Choose date',
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _openCalendarPicker(
                      state,
                    );
                  },
                  icon: const Icon(
                    Icons
                        .calendar_month_outlined,
                    size: 19,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Monday - Friday selector
          Row(
            children: days.map(
              (day) {
                final selected = _sameDay(
                  day,
                  state.selectedDay,
                );

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(12),
                      onTap: () {
                        widget.viewModel
                            .selectDay(day);
                      },
                      child: AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds: 180,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _weekdayShort(
                                day.weekday,
                              ),
                              style: TextStyle(
                                color: selected
                                    ? const Color(
                                        0xFFC8D6FF,
                                      )
                                    : AppColors
                                        .textSecondary,
                                fontSize: 9,
                                letterSpacing: 0.5,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors
                                        .textPrimary,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
  Future<void> _openCalendarPicker(
    ScheduleState state,
  ) async {
    final pickedDate =
        await showDatePicker(
      context: context,

      // Date currently selected in Schedule.
      initialDate: _clampDateTo2026(
        state.selectedDay,
      ),

      // STEP 0: calendar limited to 2026.
      firstDate: DateTime(
        2026,
        1,
        1,
      ),

      lastDate: DateTime(
        2026,
        12,
        31,
      ),

      helpText: 'Select a date',

      cancelText: 'CANCEL',

      confirmText: 'SELECT',

      // Forces the visual monthly calendar.
      initialEntryMode:
          DatePickerEntryMode.calendarOnly,

      builder: (
        BuildContext context,
        Widget? child,
      ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context)
                    .colorScheme
                    .copyWith(
              primary:
                  AppColors.primary,
              surface: Colors.white,
            ),
            datePickerTheme:
                const DatePickerThemeData(
              backgroundColor:
                  Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    // User pressed Cancel.
    if (pickedDate == null) {
      return;
    }

    // Selecting a date makes Schedule jump
    // to the week containing that date.
    await widget.viewModel.selectDay(
      pickedDate,
    );
  }

  Future<void> _changeWeek(
    ScheduleState state,
    int weekOffset,
  ) async {
    final targetDate =
        state.selectedDay.add(
      Duration(
        days: weekOffset * 7,
      ),
    );

    // STEP 0 only supports 2026.
    if (targetDate.year != 2026) {
      return;
    }

    await widget.viewModel.selectDay(
      targetDate,
    );
  }

  DateTime _clampDateTo2026(
    DateTime date,
  ) {
    final firstDate =
        DateTime(2026, 1, 1);

    final lastDate =
        DateTime(2026, 12, 31);

    if (date.isBefore(firstDate)) {
      return firstDate;
    }

    if (date.isAfter(lastDate)) {
      return lastDate;
    }

    return date;
  }

  String _weekRangeLabel(
    DateTime monday,
    DateTime sunday,
  ) {
    if (monday.year != sunday.year) {
      return '${_monthShort(monday.month)} '
          '${monday.day}, ${monday.year} – '
          '${_monthShort(sunday.month)} '
          '${sunday.day}, ${sunday.year}';
    }

    if (monday.month ==
        sunday.month) {
      return '${_monthShort(monday.month)} '
          '${monday.day}–${sunday.day}, '
          '${monday.year}';
    }

    return '${_monthShort(monday.month)} '
        '${monday.day} – '
        '${_monthShort(sunday.month)} '
        '${sunday.day}, '
        '${monday.year}';
  }
  Widget _buildScheduleContent(
    BuildContext context,
    ScheduleState state,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            _buildLaneHeader(state),

            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: _timelineHeight,
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildTimeColumn(),

                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMyScheduleLane(
                                state,
                              ),
                            ),
                            Expanded(
                              child: _buildFriendsLane(
                                state,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _buildCommonSlotsBanner(
            context,
            state,
          ),
        ),
      ],
    );
  }

  Widget _buildLaneHeader(
    ScheduleState state,
  ) {
    final selected = state.friends
        .where(
          (friend) =>
              state.selectedFriendIds.contains(
            friend.id,
          ),
        )
        .map((friend) => friend.name)
        .join(' & ');

    return Container(
      color: const Color(0xFFF0F4FC),
      child: Row(
        children: [
          Container(
            width: 62,
            padding: const EdgeInsets.symmetric(
              vertical: 9,
            ),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Color(0xFFDCE3EF),
                ),
              ),
            ),
            child: const Text(
              'TIME',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 9,
                horizontal: 8,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'My Schedule',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 9,
                horizontal: 8,
              ),
              color: const Color(0xFFF8FAFD),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      selected.isEmpty
                          ? 'Friends'
                          : selected,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn() {
    return Container(
      width: 62,
      height: _timelineHeight,
      color: Colors.white,
      child: Stack(
        children: [
          for (int hour = _startHour;
              hour <= _endHour;
              hour++)
            Positioned(
              top: (hour - _startHour) * 60.0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color:
                            const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          for (int hour = _startHour;
              hour < _endHour;
              hour++)
            Positioned(
              top: (hour - _startHour) * 60.0 + 4,
              right: 6,
              child: Text(
                _hourLabel(hour),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyScheduleLane(
    ScheduleState state,
  ) {
    return Container(
      height: _timelineHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
          right: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Stack(
        children: [
          ..._hourLines(),

          for (final block in state.myBlocks)
            _buildPersonalBlock(block),

          if (state.selectedSlot != null)
            _buildSelectedCommonSlot(
              state.selectedSlot!,
              alignRight: false,
            ),
        ],
      ),
    );
  }

  Widget _buildFriendsLane(
    ScheduleState state,
  ) {
    return Container(
      height: _timelineHeight,
      color: const Color(0xFFFAFBFD),
      child: Stack(
        children: [
          ..._hourLines(),

          for (final block in state.friendBlocks)
            _buildFriendBusyBlock(
              block,
              state,
            ),

          if (state.selectedSlot != null)
            _buildSelectedCommonSlot(
              state.selectedSlot!,
              alignRight: true,
            ),
        ],
      ),
    );
  }

  List<Widget> _hourLines() {
    return List.generate(
      _endHour - _startHour + 1,
      (index) => Positioned(
        top: index * 60.0,
        left: 0,
        right: 0,
        child: Container(
          height: 1,
          color: const Color(0xFFE8EDF5),
        ),
      ),
    );
  }

  Widget _buildPersonalBlock(
    ScheduleBlock block,
  ) {
    final top = _topFor(block.start);
    final height = _heightFor(
      block.start,
      block.end,
    );

    return Positioned(
      top: top,
      left: 6,
      right: 6,
      height: height,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 4,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showDetails =
                constraints.maxHeight >= 48;

            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  block.title ?? 'Busy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 2),
                  if (block.subtitle != null)
                    Text(
                      block.subtitle!,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 8.5,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  if (block.location != null)
                    Text(
                      block.location!,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 8,
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFriendBusyBlock(
    ScheduleBlock block,
    ScheduleState state,
  ) {
    final friend = _friendFor(
      block.ownerId,
      state.friends,
    );

    final top = _topFor(block.start);
    final height = _heightFor(
      block.start,
      block.end,
    );

    return Positioned(
      top: top,
      left: 6,
      right: 6,
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.friendBusy,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                friend?.name ?? 'Busy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCommonSlot(
    CommonSlot slot, {
    required bool alignRight,
  }) {
    final top = _topFor(slot.start);
    final height = _heightFor(
      slot.start,
      slot.end,
    );

    return Positioned(
      top: top + 2,
      left: 3,
      right: 3,
      height: height - 4,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.availabilityLight
                .withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.success,
              width: 1.4,
            ),
          ),
          child: alignRight
              ? null
              : const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.check_circle,
                      size: 13,
                      color: AppColors.success,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCommonSlotsBanner(
    BuildContext context,
    ScheduleState state,
  ) {
    final slots = state.commonSlots;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: slots.isEmpty
            ? null
            : () => _showCommonSlots(
                  context,
                ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.97,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: slots.isEmpty
                  ? const Color(0xFFDDE4EE)
                  : AppColors.success
                      .withValues(alpha: 0.55),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: slots.isEmpty
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFDDF8EA),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  slots.isEmpty
                      ? Icons.event_busy_outlined
                      : Icons.bolt_rounded,
                  color: slots.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.success,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      slots.isEmpty
                          ? 'No common slots found'
                          : '${slots.length} common slots found',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.selectedSlot == null
                          ? 'Try another duration or friend selection.'
                          : 'Selected: ${_slotLabel(state.selectedSlot!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (slots.isNotEmpty)
                const Icon(
                  Icons.expand_less_rounded,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    ScheduleState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 50,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              state.error ??
                  'Unable to load schedule.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.viewModel.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFriendPicker(
    BuildContext context,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: ValueListenableBuilder<ScheduleState>(
            valueListenable: widget.viewModel,
            builder: (context, state, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Friends to Compare',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose who to include in the mutual availability comparison.',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: state.friends.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final friend =
                              state.friends[index];

                          final selected = state
                              .selectedFriendIds
                              .contains(friend.id);

                          return Material(
                            color: selected
                                ? const Color(
                                    0xFFF1F6FF,
                                  )
                                : const Color(
                                    0xFFF8FAFC,
                                  ),
                            borderRadius:
                                BorderRadius.circular(14),
                            child: CheckboxListTile(
                              value: selected,
                              activeColor:
                                  AppColors.primary,
                              onChanged: (_) {
                                widget.viewModel
                                    .toggleFriend(
                                  friend.id,
                                );
                              },
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                              secondary: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary,
                                child: Text(
                                  friend.initials,
                                  style:
                                      const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                friend.fullName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'Availability shared privately',
                                style: TextStyle(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(
                          Icons.compare_arrows_rounded,
                        ),
                        label: Text(
                          'View comparison (${state.selectedFriendIds.length + 1})',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showCommonSlots(
    BuildContext context,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: ValueListenableBuilder<ScheduleState>(
            valueListenable: widget.viewModel,
            builder: (context, state, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Available Common Slots',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_weekdayLong(state.selectedDay.weekday)}, '
                      '${_monthShort(state.selectedDay.month)} '
                      '${state.selectedDay.day}',
                      style: const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount:
                            state.commonSlots.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final slot =
                              state.commonSlots[index];

                          final selected =
                              state.selectedSlot?.id ==
                                  slot.id;

                          return InkWell(
                            borderRadius:
                                BorderRadius.circular(14),
                            onTap: () {
                              widget.viewModel
                                  .selectSlot(slot);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 160,
                              ),
                              padding:
                                  const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(
                                        0xFFE5F9EF,
                                      )
                                    : const Color(
                                        0xFFF8FAFC,
                                      ),
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.success
                                      : const Color(
                                          0xFFE2E8F0,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: slot.id,
                                    groupValue: state
                                        .selectedSlot
                                        ?.id,
                                    activeColor:
                                        AppColors.success,
                                    onChanged: (_) {
                                      widget.viewModel
                                          .selectSlot(
                                        slot,
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          _slotLabel(slot),
                                          style:
                                              const TextStyle(
                                            color: AppColors
                                                .textPrimary,
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight
                                                    .w800,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        Text(
                                          '${slot.duration.inMinutes} minutes available for everyone',
                                          style:
                                              const TextStyle(
                                            color: AppColors
                                                .textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              AppColors.success,
                          foregroundColor:
                              Colors.white,
                        ),
                        onPressed:
                            state.selectedSlot == null
                                ? null
                                : () {
                                    Navigator.of(
                                      sheetContext,
                                    ).pop();

                                    _planActivity(
                                      context,
                                      state,
                                    );
                                  },
                        icon: const Icon(
                          Icons.arrow_forward,
                        ),
                        label: const Text(
                          'Plan with this slot',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _planActivity(
    BuildContext context,
    ScheduleState state,
  ) {
    final slot = state.selectedSlot;

    if (slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a common slot first.',
          ),
        ),
      );
      return;
    }

    context.push(Uri(path: AppRoutes.createActivity, queryParameters: {
      'date': '${slot.start.year}-${slot.start.month.toString().padLeft(2, '0')}-${slot.start.day.toString().padLeft(2, '0')}',
      'time': _slotLabel(slot),
    }).toString());
  }

  double _topFor(
    DateTime time,
  ) {
    final startMinutes = _startHour * 60;

    final minutes =
        time.hour * 60 + time.minute - startMinutes;

    return minutes * _pixelsPerMinute;
  }

  double _heightFor(
    DateTime start,
    DateTime end,
  ) {
    final minutes =
        end.difference(start).inMinutes;

    return (minutes * _pixelsPerMinute)
        .clamp(24, _timelineHeight);
  }

  ScheduleFriend? _friendFor(
    String? id,
    List<ScheduleFriend> friends,
  ) {
    if (id == null) {
      return null;
    }

    for (final friend in friends) {
      if (friend.id == id) {
        return friend;
      }
    }

    return null;
  }

  static DateTime _startOfWeek(
    DateTime day,
  ) {
    final normalized = DateTime(
      day.year,
      day.month,
      day.day,
    );

    return normalized.subtract(
      Duration(
        days: normalized.weekday - DateTime.monday,
      ),
    );
  }

  static bool _sameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static String _durationLabel(
    Duration duration,
  ) {
    if (duration.inMinutes == 30) {
      return '30m';
    }

    if (duration.inMinutes == 45) {
      return '45m';
    }

    if (duration.inHours == 1) {
      return '1h';
    }

    if (duration.inHours == 2) {
      return '2h';
    }

    return '${duration.inMinutes}m';
  }

  static String _slotLabel(
    CommonSlot slot,
  ) {
    return '${_timeLabel(slot.start)} – ${_timeLabel(slot.end)}';
  }

  static String _timeLabel(
    DateTime time,
  ) {
    var hour = time.hour;
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final minutes =
        time.minute.toString().padLeft(2, '0');

    return '$hour:$minutes $period';
  }

  static String _hourLabel(
    int hour,
  ) {
    final period = hour >= 12 ? 'PM' : 'AM';

    var formatted = hour;

    if (formatted == 0) {
      formatted = 12;
    } else if (formatted > 12) {
      formatted -= 12;
    }

    return '$formatted ${period == 'AM' ? 'AM' : 'PM'}';
  }

  static String _weekdayShort(
    int weekday,
  ) {
    const days = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    return days[weekday - 1];
  }

  static String _weekdayLong(
    int weekday,
  ) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[weekday - 1];
  }

  static String _monthShort(
    int month,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

class _MeChip extends StatelessWidget {
  const _MeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'Me',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendChip extends StatelessWidget {
  final ScheduleFriend friend;
  final VoidCallback onRemove;

  const _FriendChip({
    required this.friend,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        6,
        4,
        5,
        4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB8CAE9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor:
                AppColors.availabilityLight,
            child: Text(
              friend.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            friend.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}