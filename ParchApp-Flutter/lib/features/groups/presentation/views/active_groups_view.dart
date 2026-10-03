import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_navigation_bar.dart';
import '../../domain/entities/active_group.dart';
import '../view_models/active_groups_state.dart';
import '../view_models/active_groups_view_model.dart';
import '../widgets/active_group_card.dart';

const _surface = Color(0xFFF8FAFE);

class ActiveGroupsView extends StatefulWidget {
  final ActiveGroupsViewModel viewModel;
  const ActiveGroupsView({super.key, required this.viewModel});

  @override
  State<ActiveGroupsView> createState() => _ActiveGroupsViewState();
}

class _ActiveGroupsViewState extends State<ActiveGroupsView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void didUpdateWidget(covariant ActiveGroupsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<ActiveGroupsState>(
        valueListenable: widget.viewModel,
        builder: (context, state, _) => Scaffold(
          backgroundColor: _surface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            backgroundColor: _surface,
            surfaceTintColor: Colors.transparent,
            title: Row(children: [
              if (context.canPop())
                IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back)),
              const Text('Active Groups',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              const SizedBox(width: 8),
              if (state.groups.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE6EEFF),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${state.groups.length}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
            ]),
          ),
          body: SafeArea(top: false, bottom: false, child: _body(state)),
          bottomNavigationBar: const ParchNavigationBar(selectedIndex: 1),
        ),
      );

  Widget _body(ActiveGroupsState state) {
    if (state.isLoading && state.groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.groups_outlined,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(state.error ?? 'No active groups yet',
                textAlign: TextAlign.center),
            TextButton(
                onPressed: widget.viewModel.load, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final visible = state.visibleGroups;

    return RefreshIndicator(
      onRefresh: widget.viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (state.isUpdating) const LinearProgressIndicator(minHeight: 2),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final filter in GroupsFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            showCheckmark: false,
                            selected: state.filter == filter,
                            onSelected: (_) =>
                                widget.viewModel.setFilter(filter),
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                                color: state.filter == filter
                                    ? AppColors.primary
                                    : const Color(0xFFD8E2FF)),
                            shape: const StadiumBorder(),
                            label: Text(
                                '${state.labelFor(filter)} (${state.countFor(filter)})',
                                style: TextStyle(
                                    color: state.filter == filter
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 12)),
                          ),
                        ),
                    ]),
                  ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12)),
                    ),
                  const SizedBox(height: 14),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(children: [
                        const Text('No groups match this filter.',
                            textAlign: TextAlign.center),
                        TextButton(
                            onPressed: () => widget.viewModel
                                .setFilter(GroupsFilter.all),
                            child: const Text('Clear filter')),
                      ]),
                    )
                  else
                    for (final group in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ActiveGroupCard(
                          key: ValueKey(group.id),
                          group: group,
                          estimate: state.estimateFor(group),
                          busy: state.isUpdating,
                          onAction: (action) => _handleAction(group, action),
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

  Future<void> _handleAction(ActiveGroup group, GroupAction action) async {
    switch (action) {
      case GroupAction.viewSchedule:
        context.push(AppRoutes.schedule);
      case GroupAction.voteRsvp:
        if (await widget.viewModel.confirmRsvp(group)) {
          _message('RSVP confirmed for ${group.name}');
        }
      case GroupAction.dropIn:
        if (await widget.viewModel.dropIn(group)) {
          _message('You dropped in to ${group.name}');
        }
      case GroupAction.openChat:
      case GroupAction.teamChat:
      case GroupAction.chat:
        _message('Group chat is coming soon.');
      case GroupAction.roommateSync:
        _message('Roommate sync is coming soon.');
      case GroupAction.viewNotes:
        _message('Shared notes are coming soon.');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}