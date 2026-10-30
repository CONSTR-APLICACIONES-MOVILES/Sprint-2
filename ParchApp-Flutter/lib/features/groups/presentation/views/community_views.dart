import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/inline_error_notice.dart';
import '../../../../shared/widgets/parch_visuals.dart';
import '../../../../shared/widgets/parch_navigation_bar.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../../domain/repositories/community_repository.dart';

String communityError(Object e) => e is FirebaseFunctionsException
    ? e.message ?? 'Unable to connect. Try again.'
    : 'Unable to complete this request. Check your connection and retry.';

class GroupDetailsView extends StatefulWidget {
  final String groupId;
  final CommunityRepository repository;
  const GroupDetailsView(
      {super.key, required this.groupId, required this.repository});
  @override
  State<GroupDetailsView> createState() => _GroupDetailsViewState();
}

class _GroupDetailsViewState extends State<GroupDetailsView> {
  String? _session;
  bool get _sameSession => _session == widget.repository.sessionId;
  Timer? _expiryTimer;
  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _group;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _session = widget.repository.sessionId;
    _load();
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    if (!_sameSession) {
      setState(() => _error = 'Session changed. Reopen this screen.');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final group = await widget.repository.details(widget.groupId);
      if (mounted) setState(() => _group = group);
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(String invitee) async {
    if (!_sameSession) return;
    setState(() => _busy = true);
    try {
      await widget.repository.revoke(widget.groupId, invitee);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = communityError(e);
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    await _load();
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final group = _sameSession ? _group : null;
    final activities = List<Map<String, dynamic>>.from(
        (group?['activities'] as List? ?? [])
            .map((a) => Map<String, dynamic>.from(a)));
    final upcoming = activities
        .where((a) =>
            a['cancelled'] != true &&
            DateTime.tryParse(a['startTime'] ?? '')?.isAfter(DateTime.now()) ==
                true)
        .toList()
      ..sort((a, b) => (a['startTime'] as String).compareTo(b['startTime']));
    final featured = upcoming.isNotEmpty
        ? upcoming.first
        : activities.where((a) => a['cancelled'] != true).firstOrNull;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          ParchAppBar(title: group?['name'] ?? 'Group Details', showBack: true),
      bottomNavigationBar: group == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          top: BorderSide(color: AppColors.outlineSoft))),
                  child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      onPressed: () => _open(Uri(
                              path: AppRoutes.createActivity,
                              queryParameters: {'groupId': widget.groupId})
                          .toString()),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create Activity')))),
      body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) ...[
                  InlineErrorNotice(_error!),
                  TextButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Retry'))
                ],
                if (group != null) ...[
                  Row(children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.warning),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(
                            upcoming.isNotEmpty
                                ? 'UPCOMING ACTIVITY'
                                : 'LATEST ACTIVITY',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                letterSpacing: .5)))
                  ]),
                  const SizedBox(height: 12),
                  if (featured != null)
                    _featured(featured)
                  else
                    ParchSurface(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Next plan',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          const Text('No upcoming scheduled plan.')
                        ])),
                  const SizedBox(height: 22),
                  Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('MEMBERS',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: .6)),
                        ParchPill('${(group['members'] as List).length}')
                      ]),
                  const SizedBox(height: 12),
                  ParchSurface(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        for (var i = 0;
                            i < (group['members'] as List).length;
                            i++) ...[
                          if (i > 0)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          _member(group['members'][i], group['ownerId'], i),
                        ]
                      ])),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton(
                        onPressed: () => _open(Uri(
                                path: AppRoutes.schedule,
                                queryParameters: {'groupId': widget.groupId})
                            .toString()),
                        child: const Text('Compare schedules')),
                    if (group['ownerId'] == widget.repository.sessionId)
                      TextButton(
                          onPressed: () => _open(
                              '/share/group/${Uri.encodeComponent(widget.groupId)}'),
                          child: const Text('Share enrollment link'))
                  ]),
                  if (group['ownerId'] == null)
                    const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                            'Owner not recorded for this existing group.')),
                  if ((group['invitations'] as List).isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Group invitations',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    for (final i in group['invitations'] as List)
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(i['name'] ?? i['inviteeId']),
                          subtitle: Text(i['state']),
                          trailing: i['state'] == 'pending'
                              ? TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _revoke(i['inviteeId']),
                                  child: const Text('Revoke'))
                              : null)
                  ],
                  const SizedBox(height: 24),
                  const Text('RECENT ACTIVITIES',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: .6)),
                  const SizedBox(height: 8),
                  const Text(
                      'Latest 100 activities, including proposals and cancelled plans.',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  if (activities.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No activities yet.')),
                  for (final a
                      in activities.where((a) => a['id'] != featured?['id']))
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _activity(a)),
                ],
              ])),
    );
  }

  Widget _member(dynamic member, dynamic owner, int index) {
    final expired = member['statusExpiresAt'] != null &&
        !DateTime.parse(member['statusExpiresAt']).isAfter(DateTime.now());
    final status = _status(
        expired && member['status'] != null ? 'offline' : member['status']);
    return Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ParchAvatar(member['name'], index: index),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(member['name'],
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('${member['id'] == owner ? 'Owner · ' : ''}$status',
                    style: const TextStyle(fontSize: 12)),
                if (member['id'] == widget.repository.sessionId)
                  const Padding(
                      padding: EdgeInsets.only(top: 5), child: ParchPill('You'))
              ]))
        ]));
  }

  Widget _featured(Map<String, dynamic> a) {
    final counts = a['attendance'] as Map,
        total = (counts['accepted'] as num) +
            (counts['maybe'] as num) +
            (counts['declined'] as num) +
            (counts['pending'] as num? ?? 0),
        accepted = counts['accepted'] as num;
    final allAccepted = total > 0 && accepted == total;
    final pending = (counts['pending'] as num? ?? 0) > 0;
    final attendanceColor = allAccepted ? AppColors.success : AppColors.warning;
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD7E5FF))),
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 5, color: attendanceColor),
          Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: ParchPill(
                            allAccepted
                                ? 'Everyone accepted'
                                : pending
                                    ? 'Awaiting responses'
                                    : 'All responses received',
                            color: attendanceColor,
                            icon: allAccepted
                                ? Icons.check_circle_outline
                                : Icons.people_outline)),
                    const SizedBox(height: 12),
                    Text(a['title'],
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    _groupLogistic(
                        Icons.calendar_month_outlined, _activityDate(a)),
                    const SizedBox(height: 10),
                    _groupLogistic(
                        Icons.location_on_outlined,
                        (a['location'] as String? ?? '').isEmpty
                            ? 'Location not set'
                            : a['location']),
                    const Divider(height: 30),
                    Text('$accepted of $total accepted',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                            minHeight: 7,
                            value: total == 0 ? 0 : accepted / total,
                            color: AppColors.success,
                            backgroundColor: const Color(0xFFFFECC3))),
                    const SizedBox(height: 10),
                    Text(
                        '${counts['pending'] ?? 0} pending · ${counts['maybe']} maybe · ${counts['declined']} declined',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13))),
                        onPressed: () => _open(AppRoutes.studySession(a['id'])),
                        label: const Text('View activity'),
                        icon: const Icon(Icons.arrow_forward, size: 18)),
                  ]))
        ]));
  }

  Widget _groupLogistic(IconData icon, String text) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))
      ]);

  String _activityDate(Map<String, dynamic> activity) {
    final canonical = DateTime.tryParse(activity['startTime'] ?? '');
    if (canonical != null) {
      final local = canonical.toUtc().subtract(const Duration(hours: 5));
      return '${local.day}/${local.month}/${local.year} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} · Bogotá';
    }
    final proposed =
        '${activity['date'] ?? ''} ${activity['time'] ?? ''}'.trim();
    return proposed.isEmpty ? 'Not scheduled' : '$proposed (Bogotá)';
  }

  String _status(dynamic status) => switch (status) {
        'active' => 'Active',
        'busy' => 'Busy',
        'inClass' => 'In class',
        'focused' => 'Focused',
        'inTransit' => 'In transit',
        'offline' => 'Offline',
        _ => 'Status not shared'
      };
  Widget _activity(Map<String, dynamic> a) => ParchSurface(
      padding: const EdgeInsets.all(14),
      child: InkWell(
          onTap: () => _open(AppRoutes.studySession(a['id'])),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(12)),
                child:
                    const Icon(Icons.event_outlined, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(a['title'],
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(_activityDate(a), style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  ParchPill(
                      a['cancelled'] == true
                          ? 'Cancelled'
                          : a['status'] == 'CONFIRMED'
                              ? 'Confirmed'
                              : 'Proposed',
                      color: a['cancelled'] == true
                          ? AppColors.error
                          : a['status'] == 'CONFIRMED'
                              ? AppColors.success
                              : AppColors.warning)
                ]))
          ])));
}

class GroupInvitationsView extends StatefulWidget {
  final CommunityRepository repository;
  const GroupInvitationsView({super.key, required this.repository});
  @override
  State<GroupInvitationsView> createState() => _GroupInvitationsViewState();
}

class _GroupInvitationsViewState extends State<GroupInvitationsView> {
  String? _session;
  bool get _sameSession => _session == widget.repository.sessionId;
  List<Map<String, dynamic>>? _items;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _session = widget.repository.sessionId;
    _load();
  }

  Future<void> _load() async {
    if (!_sameSession) {
      setState(() => _error = 'Session changed. Reopen this screen.');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await widget.repository.invitations();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respond(String id, String response) async {
    if (!_sameSession) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.respond(id, response);
      if (!mounted) {
        return;
      }
      if (response == 'accepted') {
        await context.push(AppRoutes.groupDetails(id));
      }
      if (mounted) {
        setState(() => _busy = false);
        await _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = communityError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const ParchAppBar(title: 'Group invitations', showBack: true),
      body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!),
              TextButton(
                  onPressed: _busy ? null : _load, child: const Text('Retry'))
            ],
            if (_items?.isEmpty == true)
              const Text('No group invitations yet.'),
            for (final item
                in (_sameSession ? _items : null) ?? <Map<String, dynamic>>[])
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['groupName'],
                                style: Theme.of(context).textTheme.titleLarge),
                            Text('State: ${item['state']}'),
                            Text('Expires: ${item['expiresAt']}'),
                            if (item['state'] == 'pending')
                              Wrap(spacing: 8, children: [
                                FilledButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _respond(
                                            item['groupId'], 'accepted'),
                                    child: const Text('Accept')),
                                TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _respond(
                                            item['groupId'], 'declined'),
                                    child: const Text('Decline')),
                              ]),
                            if (item['state'] == 'accepted')
                              TextButton(
                                  onPressed: () => context.push(
                                      AppRoutes.groupDetails(item['groupId'])),
                                  child: const Text('Open group')),
                          ]))),
          ])));
}

class CreateGroupView extends StatefulWidget {
  final CommunityRepository repository;
  const CreateGroupView({super.key, required this.repository});
  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  String? _session;
  bool get _sameSession => _session == widget.repository.sessionId;
  final _name = TextEditingController();
  final _scroll = ScrollController();
  final _ids = <String>{};
  String _key = List.generate(24,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
  String _category = 'study';
  List<Map<String, dynamic>> _peers = [];
  String? _error;
  bool _loading = true, _saving = false, _review = false, _uncertain = false;
  @override
  void initState() {
    super.initState();
    _session = widget.repository.sessionId;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pending = await widget.repository.pendingCreation();
      if (!mounted) {
        return;
      }
      if (pending != null) {
        setState(() {
          _key = pending['requestId'];
          _name.text = pending['name'];
          _category = pending['category'];
          _ids
            ..clear()
            ..addAll(List<String>.from(pending['inviteeIds']));
          _review = true;
          _uncertain = true;
        });
      }
      final peers = await widget.repository.peers();
      if (mounted) setState(() => _peers = peers);
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (!_sameSession) {
      setState(() => _error = 'Session changed. Reopen Create Group.');
      return;
    }
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final receipt = await widget.repository
          .create(_key, _name.text.trim(), _category, _ids.toList());
      if (mounted) context.go(AppRoutes.groupDetails(receipt['groupId']));
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _uncertain = !(e is FirebaseFunctionsException &&
              [
                'invalid-argument',
                'permission-denied',
                'unauthenticated',
                'resource-exhausted',
                'already-exists'
              ].contains(e.code));
          _error =
              '${communityError(e)}${_uncertain ? ' Retry this same creation to recover its result.' : ''}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving && !_uncertain,
      child: Scaffold(
          appBar: const ParchAppBar(showBack: true),
          bottomNavigationBar: const ParchNavigationBar(selectedIndex: 1),
          body: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Create Group',
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text(
                    'Set up your group and invite people to plan together.'),
                const SizedBox(height: 24),
                if (_loading || _saving) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Text(_error!),
                  if (!_review)
                    TextButton(onPressed: _load, child: const Text('Retry'))
                ],
                if (!_review) ...[
                  TextField(
                      controller: _name,
                      maxLength: 80,
                      decoration:
                          const InputDecoration(labelText: 'Group name'),
                      onChanged: (_) => setState(() {})),
                  DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ['study', 'social', 'sports', 'living']
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!)),
                  const SizedBox(height: 20),
                  const ParchSurface(
                      color: AppColors.blueTint,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('INVITE PARTICIPANTS',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 10),
                            Text(
                                'Invite people from your shared groups. They join after accepting. Invitations expire in 7 days.'),
                            SizedBox(height: 10),
                            Text(
                                'Create the group first to generate its enrollment link or QR.',
                                style: TextStyle(fontSize: 12))
                          ])),
                  for (final p in _peers)
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p['name']),
                        value: _ids.contains(p['id']),
                        onChanged: (v) => setState(() {
                              v == true
                                  ? _ids.add(p['id'])
                                  : _ids.remove(p['id']);
                            })),
                  if (!_loading && _error == null && _peers.isEmpty)
                    const Text(
                        'No shared peers yet. You can create a group for yourself.'),
                  FilledButton(
                      onPressed: !_loading && _name.text.trim().length >= 2
                          ? () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _review = true;
                                _error = null;
                              });
                              _scroll.jumpTo(0);
                            }
                          : null,
                      child: const Text('Review group')),
                ] else ...[
                  Text('Review group',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(_name.text.trim()),
                  Text('Category: $_category'),
                  const Text('You will be the owner and first member.'),
                  for (final id in _ids)
                    ListTile(
                        title: Text(_peers
                                .where((p) => p['id'] == id)
                                .firstOrNull?['name'] ??
                            id),
                        subtitle:
                            const Text('Will receive an internal invitation')),
                  Text(
                      '${_ids.length} internal invitations. No email or public link will be sent.'),
                  FilledButton(
                      onPressed: _saving ? null : _create,
                      child:
                          Text(_uncertain ? 'Retry creation' : 'Create Group')),
                  TextButton(
                      onPressed: _saving || _uncertain
                          ? null
                          : () => setState(() => _review = false),
                      child: const Text('Back to details')),
                ],
              ])));
}
