import '../../../../shared/widgets/parch_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_alert.dart';
import '../view_models/alerts_state.dart';
import '../view_models/alerts_view_model.dart';
import '../widgets/alert_card.dart';
import '../widgets/alerts_sheets.dart';

class AlertsView extends StatefulWidget {
  final AlertsViewModel viewModel;
  const AlertsView({super.key, required this.viewModel});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  final _search = TextEditingController();
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    _search.text = widget.viewModel.value.query;
    widget.viewModel.load();
  }

  @override
  void didUpdateWidget(covariant AlertsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _search.text = widget.viewModel.value.query;
      widget.viewModel.load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AlertsState>(
        valueListenable: widget.viewModel,
        builder: (context, state, _) => Scaffold(
          backgroundColor: alertsSurface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            backgroundColor: alertsSurface,
            surfaceTintColor: Colors.transparent,
            title: Row(children: [
              Image.asset('assets/images/parchapp_logo.png',
                  width: 32, height: 32, excludeFromSemantics: true),
              const SizedBox(width: 8),
              const Flexible(
                  child: Text('ParchApp',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20))),
            ]),
            actions: [
              IconButton(
                  tooltip: 'Search alerts',
                  onPressed: () =>
                      setState(() => _searchVisible = !_searchVisible),
                  icon: const Icon(Icons.search)),
              IconButton(
                  tooltip: 'Mark all alerts read',
                  onPressed: state.isUpdating ||
                          state.isLoading ||
                          state.unreadCount == 0
                      ? null
                      : _markRead,
                  icon: Badge(
                      isLabelVisible: state.unreadCount > 0,
                      backgroundColor: const Color(0xFFBA1A1A),
                      child: const Icon(Icons.notifications))),
              IconButton(
                  tooltip: 'Your profile',
                  onPressed: () => showAlertsSheet<void>(context,
                      child: const AlertProfileSheet(friendRequest: false)),
                  icon: const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child:
                          Icon(Icons.person, color: Colors.white, size: 22))),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
              top: false,
              bottom: false,
              child: RefreshIndicator(
                onRefresh: widget.viewModel.load,
                child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                          child: Center(
                              child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Wrap(
                                          spacing: 10,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            const Text('Alerts',
                                                style: TextStyle(
                                                    color: Color(0xFF001A41),
                                                    fontSize: 22,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            if (state.unreadCount > 0)
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 9,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFFFDAD6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  child: Text(
                                                      '${state.unreadCount} new',
                                                      style: const TextStyle(
                                                          color:
                                                              Color(0xFF93000A),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight
                                                              .w800))),
                                          ]),
                                      TextButton.icon(
                                          onPressed: state.isUpdating ||
                                                  state.isLoading ||
                                                  state.unreadCount == 0
                                              ? null
                                              : _markRead,
                                          icon: const Icon(Icons.done_all,
                                              size: 18),
                                          label: const Text('Mark read')),
                                    ]),
                                const Text('Stay updated & coordinate quickly',
                                    style: TextStyle(
                                        color: Color(0xFF43474E),
                                        fontSize: 13)),
                                if (_searchVisible) ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                      controller: _search,
                                      onChanged: widget.viewModel.search,
                                      decoration: InputDecoration(
                                          hintText:
                                              'Search activities, friends, groups...',
                                          prefixIcon: const Icon(Icons.search),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                          suffixIcon: IconButton(
                                              tooltip: 'Clear search',
                                              onPressed: () {
                                                _search.clear();
                                                widget.viewModel.search('');
                                              },
                                              icon: const Icon(Icons.close)))),
                                ],
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: [
                                      for (final filter in AlertsFilter.values)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            showCheckmark: false,
                                            selected: state.filter == filter,
                                            onSelected: (_) => widget.viewModel
                                                .setFilter(filter),
                                            selectedColor: AppColors.primary,
                                            backgroundColor: Colors.white,
                                            side: BorderSide(
                                                color: state.filter == filter
                                                    ? AppColors.primary
                                                    : const Color(0xFFD8E2FF)),
                                            shape: const StadiumBorder(),
                                            avatar: Icon(_filterIcon(filter),
                                                size: 16,
                                                color: state.filter == filter
                                                    ? Colors.white
                                                    : filter ==
                                                            AlertsFilter
                                                                .priority
                                                        ? const Color(
                                                            0xFFBA1A1A)
                                                        : AppColors.primary),
                                            label: Text(_filterLabel(filter),
                                                style: TextStyle(
                                                    color:
                                                        state.filter == filter
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF43474E),
                                                    fontSize: 12)),
                                          ),
                                        ),
                                    ])),
                              ],
                            )),
                      ))),
                      if (state.isLoading)
                        const SliverToBoxAdapter(
                            child: Padding(
                                padding: EdgeInsets.all(40),
                                child:
                                    Center(child: CircularProgressIndicator())))
                      else ...[
                        if (state.error != null)
                          SliverToBoxAdapter(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(children: [
                                    Text(state.error!,
                                        textAlign: TextAlign.center),
                                    TextButton(
                                        onPressed: widget.viewModel.load,
                                        child: const Text('Retry')),
                                  ]))),
                        if (state.isUpdating)
                          const SliverToBoxAdapter(
                              child: LinearProgressIndicator()),
                        if (state.visibleAlerts.isEmpty && state.error == null)
                          SliverToBoxAdapter(
                              child: Padding(
                                  padding: const EdgeInsets.all(36),
                                  child: Column(children: [
                                    const Icon(
                                        Icons.notifications_paused_outlined,
                                        size: 48,
                                        color: AppColors.primary),
                                    const SizedBox(height: 16),
                                    const Text('All caught up!',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'No notifications match the selected filter.',
                                        textAlign: TextAlign.center),
                                    TextButton(
                                        onPressed: () {
                                          _search.clear();
                                          widget.viewModel.clearFilters();
                                        },
                                        child: const Text('Clear Filters')),
                                  ]))),
                        for (final period in AlertPeriod.values)
                          if (state.visibleAlerts
                              .any((alert) => alert.period == period)) ...[
                            SliverToBoxAdapter(
                                child: Center(
                                    child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 640),
                                        child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                20, 20, 20, 14),
                                            child: Row(children: [
                                              Expanded(
                                                  child: Text(
                                                      period == AlertPeriod.today
                                                          ? 'TODAY  •'
                                                          : 'EARLIER THIS WEEK',
                                                      style: TextStyle(
                                                          color: period ==
                                                                  AlertPeriod
                                                                      .today
                                                              ? AppColors
                                                                  .primary
                                                              : AppColors
                                                                  .textSecondary,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: 0.7))),
                                              Text(
                                                  '${state.visibleAlerts.where((alert) => alert.period == period).length} alerts',
                                                  style: const TextStyle(
                                                      color: Color(0xFF74777F),
                                                      fontSize: 11)),
                                            ]))))),
                            SliverList.list(children: [
                              for (final alert in state.visibleAlerts
                                  .where((alert) => alert.period == period))
                                Center(
                                    child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 640),
                                        child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 14),
                                            child: AlertCard(
                                              key: ValueKey(alert.id),
                                              alert: alert,
                                              busy: state.isUpdating,
                                              onRespond: (response) =>
                                                  _respond(alert, response),
                                              onCreateActivity: _createActivity,
                                              onProfile: () => _profile(alert),
                                              onDetails: () => _details(alert),
                                            )))),
                            ]),
                          ],
                      ],
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ]),
              )),
          bottomNavigationBar: const ParchNavigationBar(),
        ),
      );

  String _filterLabel(AlertsFilter filter) => switch (filter) {
        AlertsFilter.all => 'All',
        AlertsFilter.priority => 'Priority',
        AlertsFilter.invitations => 'Invitations',
        AlertsFilter.schedule => 'Schedule',
        AlertsFilter.friends => 'Friends',
        AlertsFilter.groups => 'Groups',
        AlertsFilter.unread => 'Unread',
      };
  IconData _filterIcon(AlertsFilter filter) => switch (filter) {
        AlertsFilter.all => Icons.notifications,
        AlertsFilter.priority => Icons.error,
        AlertsFilter.invitations => Icons.mail,
        AlertsFilter.schedule => Icons.schedule,
        AlertsFilter.friends => Icons.person_add,
        AlertsFilter.groups => Icons.groups,
        AlertsFilter.unread => Icons.circle,
      };

  Future<void> _markRead() async {
    if (await widget.viewModel.markAllRead()) {
      _message('All notifications marked as read');
    }
  }

  Future<void> _respond(AppAlert alert, AlertResponse response) async {
    if (response == AlertResponse.declined) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Decline request?'),
                  content: Text(alert.title),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Decline')),
                  ]));
      if (!mounted || confirmed != true) return;
    }
    final updated = await widget.viewModel.respond(alert, response);
    if (updated) {
      _message(switch (response) {
        AlertResponse.accepted => 'Request accepted',
        AlertResponse.maybe => 'Response saved: Maybe',
        AlertResponse.declined => 'Request declined',
        AlertResponse.acknowledged => 'Schedule change acknowledged',
        AlertResponse.joined => 'Group invitation accepted',
        AlertResponse.dismissed => 'Alert dismissed',
        AlertResponse.onMyWay => 'Response saved: On my way',
      });
    }
  }

  Future<void> _profile(AppAlert alert) async {
    final accept =
        await showAlertsSheet<bool>(context, child: const AlertProfileSheet());
    if (mounted && accept == true) {
      await _respond(alert, AlertResponse.accepted);
    }
  }

  Future<void> _createActivity() async {
    final submitted =
        await showAlertsSheet<bool>(context, child: const QuickActivitySheet());
    // Activities owns creation and invitations; this sheet is a draft preview.
    if (submitted == true) {
      _message('Activity invitations are coming soon. Nothing was sent.');
    }
  }

  void _details(AppAlert alert) {
    if (alert.studySessionId != null) {
      context.push(AppRoutes.studySession(alert.studySessionId!));
      return;
    }
    showAlertsSheet<void>(context,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(alert.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Text(alert.description),
              if (alert.kind == AlertKind.reminder) ...[
                const SizedBox(height: 16),
                const Text('Map directions are coming soon.'),
              ],
            ]));
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
