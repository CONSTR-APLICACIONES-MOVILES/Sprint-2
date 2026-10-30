import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../../domain/repositories/expansion_repository.dart';
import 'expansion_views.dart' show SessionState;

class UsernameView extends StatefulWidget {
  final ExpansionRepository repository;
  const UsernameView({super.key, required this.repository});
  @override
  State<UsernameView> createState() => _UsernameState();
}

class _UsernameState extends SessionState<UsernameView> {
  @override
  ExpansionRepository get repository => widget.repository;
  final _username = TextEditingController();
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => action(() async {
        final profile = await request('getProfile', {});
        if (mounted) {
          _username.text = profile['username'] ?? '';
          setState(() => loaded = true);
        }
      });
  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() => action(() async {
        final result = await request('setUsername',
            {'username': _username.text, 'clientUserId': repository.sessionId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Username saved: @${result['username']}')));
          context.pop();
        }
      });
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const ParchAppBar(title: 'Username', showBack: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        feedback(),
        const Text(
            'Choose a unique username so people can find you without sharing a group. Your public directory entry shows only your name and username.'),
        const SizedBox(height: 16),
        TextField(
            controller: _username,
            enabled: loaded && !busy && sameSession,
            autocorrect: false,
            decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                helperText: '3–24 letters, numbers, dots or underscores'),
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: loaded &&
                    !busy &&
                    sameSession &&
                    RegExp(r'^@?[a-zA-Z0-9._]{3,24}$')
                        .hasMatch(_username.text.trim())
                ? _save
                : null,
            child: const Text('Save username')),
        if (error != null)
          TextButton(
              onPressed: busy ? null : _load,
              child: const Text('Retry loading')),
      ]));
}

class FriendsView extends StatefulWidget {
  final ExpansionRepository repository;
  final bool searchOnly;
  const FriendsView(
      {super.key, required this.repository, this.searchOnly = false});
  @override
  State<FriendsView> createState() => _FriendsState();
}

class _FriendsState extends SessionState<FriendsView> {
  @override
  ExpansionRepository get repository => widget.repository;
  final _query = TextEditingController();
  Timer? _debounce;
  int _revision = 0;
  bool loading = false, offline = false;
  String? cursor, cachedAt;
  List<Map<String, dynamic>> rows = [];
  bool get searching => widget.searchOnly || _query.text.trim().isNotEmpty;
  @override
  void initState() {
    super.initState();
    if (!widget.searchOnly) _load();
  }

  @override
  void dispose() {
    _revision++;
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final revision = ++_revision;
    if (searching && _query.text.trim().replaceFirst('@', '').length < 2) {
      setState(() {
        rows = [];
        cursor = null;
        loading = false;
        error = null;
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
      if (!more) {
        offline = false;
        cachedAt = null;
      }
      if (!more) {
        rows = [];
        cursor = null;
      }
    });
    final search = searching;
    try {
      final result = await request(search ? 'searchPeople' : 'getFriends', {
        if (search) 'query': _query.text.trim(),
        'limit': 20,
        if (more && cursor != null) 'cursor': cursor
      });
      if (!mounted || revision != _revision) return;
      setState(() {
        final list = (result[search ? 'people' : 'relationships'] as List)
            .map((r) => Map<String, dynamic>.from(r));
        rows = [if (more) ...rows, ...list];
        cursor = result['cursor'];
        offline = result['offline'] == true;
        cachedAt = result['cachedAt'];
      });
    } catch (e) {
      if (mounted && revision == _revision) {
        setState(() => error = e is FirebaseFunctionsException
            ? e.message
            : 'Requires connection. Retry when online.');
      }
    } finally {
      if (mounted && revision == _revision) setState(() => loading = false);
    }
  }

  Future<void> _openPerson(String id) async {
    await context.push('/people/${Uri.encodeComponent(id)}');
    if (mounted && sameSession) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: ParchAppBar(
          title: widget.searchOnly ? 'Find people' : 'Friends', showBack: true),
      body: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                feedback(),
                const Text(
                    'Search by username. Friendship requests need acceptance and do not reveal calendars or locations.'),
                TextField(
                    controller: _query,
                    enabled: sameSession,
                    decoration: const InputDecoration(
                        labelText: 'Search username',
                        prefixIcon: Icon(Icons.search)),
                    onChanged: (_) {
                      _revision++;
                      _debounce?.cancel();
                      setState(() {
                        rows = [];
                        cursor = null;
                        error = null;
                        loading = false;
                      });
                      _debounce = Timer(
                          const Duration(milliseconds: 300), () => _load());
                    }),
                Wrap(spacing: 12, children: [
                  TextButton(
                      onPressed: () => context.push('/username'),
                      child: const Text('Set my username')),
                  TextButton(
                      onPressed: () => context.push('/join'),
                      child: const Text('Enter invitation code'))
                ]),
                if (loading) const LinearProgressIndicator(),
                if (offline)
                  Text(
                      'Saved copy: ${cachedAt ?? 'date unavailable'}. Search and friendship changes require connection.'),
                if (!loading && error == null && rows.isEmpty)
                  Text(searching
                      ? 'No results. Enter at least two username characters.'
                      : 'No friends or requests yet. Search for someone to send a request.'),
                if (sameSession)
                  for (final row in rows)
                    Builder(builder: (context) {
                      final p = searching
                          ? row
                          : Map<String, dynamic>.from(row['person']);
                      final state = searching
                          ? 'Public profile'
                          : row['state'] == 'accepted'
                              ? 'Friends'
                              : row['direction'] == 'incoming'
                                  ? 'Incoming request'
                                  : 'Request sent';
                      return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(p['name']),
                          subtitle: Text(
                              '${p['username'] == null ? 'No username' : '@${p['username']}'} · $state'),
                          onTap: () => _openPerson(p['id']));
                    }),
                if (cursor != null)
                  TextButton(
                      onPressed: loading ? null : () => _load(more: true),
                      child: const Text('Load more')),
                if (error != null)
                  TextButton(
                      onPressed: loading ? null : () => _load(),
                      child: const Text('Retry')),
              ])));
}

class PublicPersonView extends StatefulWidget {
  final ExpansionRepository repository;
  final String userId;
  const PublicPersonView(
      {super.key, required this.repository, required this.userId});
  @override
  State<PublicPersonView> createState() => _PersonState();
}

class _PersonState extends SessionState<PublicPersonView> {
  @override
  ExpansionRepository get repository => widget.repository;
  Map<String, dynamic>? person;
  Map<String, dynamic>? pending;
  bool legacy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => action(() async {
        Map<String, dynamic> result;
        try {
          result = await request('getPublicPerson', {'userId': widget.userId});
          legacy = false;
        } on FirebaseFunctionsException catch (e) {
          if (e.code != 'not-found') rethrow;
          result = await request('getSharedProfile', {'userId': widget.userId});
          legacy = true;
        }
        if (mounted) {
          setState(() {
            person = result;
            pending = null;
          });
        }
      });
  Future<void> _change(String name) async {
    if (name == 'remove') {
      final yes = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text('Remove friendship?'),
                  content:
                      const Text('Your shared groups will stay unchanged.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Keep friendship')),
                    TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Remove'))
                  ]));
      if (yes != true || !mounted) return;
    }
    pending = {
      'userId': widget.userId,
      'action': name,
      'expectedVersion': person!['friendship']['version'],
      'clientUserId': repository.sessionId
    };
    await _send();
  }

  Future<void> _send() => action(() async {
        final result = await request('changeFriendship', pending!);
        if (mounted) {
          setState(() {
            person = {...person!, 'friendship': result};
            pending = null;
          });
        }
      });
  @override
  Widget build(BuildContext context) {
    final p = sameSession ? person : null, r = p?['friendship'] as Map?;
    final enabled = !busy && pending == null;
    return Scaffold(
        appBar: const ParchAppBar(title: 'Public profile', showBack: true),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          feedback(),
          if (p != null) ...[
            Text(p['name'], style: Theme.of(context).textTheme.headlineSmall),
            Text(p['username'] == null
                ? 'No public username yet'
                : '@${p['username']}'),
            const Text(
                'Only this public identity is shared. Friendship does not grant calendar access.'),
            if (legacy)
              const Text(
                  'This legacy account is visible through a shared group. It needs a username before using friendship requests.'),
            if (!legacy && p['self'] != true) ...[
              Text(r?['state'] == 'accepted'
                  ? 'Friends'
                  : r?['state'] == 'pending'
                      ? (r?['direction'] == 'incoming'
                          ? 'Incoming request'
                          : 'Request sent')
                      : 'Not friends'),
              if (['none', 'removed', 'declined'].contains(r?['state']))
                FilledButton(
                    onPressed: enabled ? () => _change('request') : null,
                    child: const Text('Send friend request')),
              if (r?['state'] == 'pending' &&
                  r?['direction'] == 'incoming') ...[
                FilledButton(
                    onPressed: enabled ? () => _change('accept') : null,
                    child: const Text('Accept request')),
                TextButton(
                    onPressed: enabled ? () => _change('decline') : null,
                    child: const Text('Decline request'))
              ],
              if (r?['state'] == 'pending' && r?['direction'] == 'outgoing')
                TextButton(
                    onPressed: enabled ? () => _change('cancel') : null,
                    child: const Text('Cancel request')),
              if (r?['state'] == 'accepted')
                TextButton(
                    onPressed: enabled ? () => _change('remove') : null,
                    child: const Text('Remove friend')),
            ],
          ],
          if (pending != null && !busy) ...[
            const Text(
                'No acknowledgement received. Retry the same action or refresh to check its state.'),
            FilledButton(onPressed: _send, child: const Text('Retry action'))
          ],
          TextButton(
              onPressed: busy ? null : _load,
              child: const Text('Refresh profile')),
        ]));
  }
}
