import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../../domain/repositories/expansion_repository.dart';
import 'expansion_views.dart';

class ActivityParticipantsView extends StatefulWidget {
  final ExpansionRepository repository;
  final String activityId;
  const ActivityParticipantsView(
      {super.key, required this.repository, required this.activityId});
  @override
  State<ActivityParticipantsView> createState() =>
      _ActivityParticipantsViewState();
}

class _ActivityParticipantsViewState
    extends SessionState<ActivityParticipantsView> {
  @override
  ExpansionRepository get repository => widget.repository;
  Map<String, dynamic>? _data;
  final List<Map<String, dynamic>> _friends = [];
  final Set<String> _sent = {};
  @override
  void initState() {
    super.initState();
    action(_load);
  }

  Future<void> _load() async {
    final result = await request(
        'getActivityParticipants', {'activityId': widget.activityId});
    if (mounted) setState(() => _data = result);
    if (result['canInviteFriends'] == true) {
      final rows = <Map<String, dynamic>>[];
      String? cursor;
      do {
        final page = await request(
            'getFriends', {if (cursor != null) 'cursor': cursor, 'limit': 50});
        rows.addAll((page['relationships'] as List)
            .where((r) => r['state'] == 'accepted')
            .map((r) => Map<String, dynamic>.from(r['person'])));
        cursor = page['cursor'] as String?;
      } while (cursor != null);
      if (mounted) {
        setState(() {
          _friends.clear();
          _friends.addAll(rows);
        });
      }
    }
  }

  Future<void> _change(String command, [String? id]) async {
    if (command == 'remove') {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Remove participant?'),
                  content: const Text(
                      'Their activity invitation will be removed. They will remain in the group.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep participant')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Remove'))
                  ]));
      if (confirmed != true || !mounted) return;
    }
    await action(() async {
      await request('changeActivityParticipants', {
        'activityId': widget.activityId,
        'action': command,
        if (id != null) 'userId': id,
        'expectedVersion': _data!['version'],
        'clientUserId': repository.sessionId,
      });
      await _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = sameSession ? _data : null;
    final manage = data?['canManage'] == true;
    final cancelled = data?['cancelled'] == true;
    return Scaffold(
        appBar:
            const ParchAppBar(title: 'Activity participants', showBack: true),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          feedback(),
          Text(
              manage
                  ? 'Invite group members or manage existing participants.'
                  : 'Join this activity to confirm your attendance.',
              style: const TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          if (data != null && !manage && data['canJoin'] == true)
            FilledButton.icon(
                onPressed: busy ? null : () => _change('join'),
                icon: const Icon(Icons.event_available),
                label: const Text('Join activity')),
          if (data != null && !manage && data['joined'] == true && !cancelled)
            OutlinedButton(
                onPressed: busy
                    ? null
                    : () => context.push(
                        '/activities/${Uri.encodeComponent(widget.activityId)}/invitation'),
                child: const Text('View Invitation')),
          if (cancelled) const Text('This activity is cancelled.'),
          const SizedBox(height: 16),
          for (final person in data?['members'] as List? ?? [])
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(person['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(person['organizer'] == true
                                  ? 'Organizer'
                                  : person['invited'] != true
                                      ? 'Not invited'
                                      : person['response'] ??
                                          'Awaiting response'),
                              if (manage &&
                                  person['organizer'] != true &&
                                  !cancelled) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () => _change(
                                            person['invited'] == true
                                                ? 'remove'
                                                : 'invite',
                                            person['id']),
                                    child: Text(person['invited'] == true
                                        ? 'Remove participant'
                                        : 'Invite to activity')),
                              ],
                            ])))),
          if (manage && data != null) ...[
            const SizedBox(height: 16),
            const Text(
                'Friends must join this group before they can participate in its activities.',
                style: TextStyle(height: 1.5)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => context.push(
                        '/share/group/${Uri.encodeComponent(data['groupId'])}'),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Invite friends to group')),
            if (data['canInviteFriends'] == true) ...[
              const SizedBox(height: 16),
              for (final friend in _friends.where((f) =>
                  !(data['members'] as List).any((m) => m['id'] == f['id'])))
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(friend['name']),
                      subtitle: Text(_sent.contains(friend['id'])
                          ? 'Invitation sent. They must accept before joining the activity.'
                          : '@${friend['username']}'),
                      trailing: TextButton(
                          onPressed: busy || _sent.contains(friend['id'])
                              ? null
                              : () => action(() async {
                                    await request('inviteGroupFriend', {
                                      'groupId': data['groupId'],
                                      'userId': friend['id'],
                                      'clientUserId': repository.sessionId
                                    });
                                    if (mounted) {
                                      setState(() => _sent.add(friend['id']));
                                    }
                                  }),
                          child: Text(_sent.contains(friend['id'])
                              ? 'Sent'
                              : 'Invite to group')),
                    )),
            ],
          ],
          const SizedBox(height: 16),
          TextButton(
              onPressed: busy ? null : () => action(_load),
              child: const Text('Reload participants')),
        ]));
  }
}
