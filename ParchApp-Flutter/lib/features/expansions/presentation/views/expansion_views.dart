import 'dart:async';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../../../../shared/widgets/parch_navigation_bar.dart';
import '../../domain/repositories/expansion_repository.dart';
import '../../domain/repositories/external_actions.dart';

String _error(Object e) => e is FirebaseFunctionsException
    ? e.message ?? 'Request failed. Retry when connected.'
    : 'Unable to complete this action. Check connection and retry.';
String _key() => List.generate(24,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
    .join();

abstract class SessionState<T extends StatefulWidget> extends State<T> {
  ExpansionRepository get repository;
  String? _owner;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _owner = repository.sessionId;
  }

  bool get sameSession => _owner == repository.sessionId;
  Future<Map<String, dynamic>> request(
      String name, Map<String, dynamic> input) async {
    if (!sameSession) throw StateError('Session changed.');
    final result = await repository.request(name, input);
    if (!sameSession) throw StateError('Session changed.');
    return result;
  }

  Future<void> action(Future<void> Function() work) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!sameSession) throw StateError('Session changed.');
      await work();
    } catch (e) {
      if (mounted) setState(() => error = _error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget feedback() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (busy) const LinearProgressIndicator(),
        if (!sameSession) const Text('Session changed. Reopen this screen.'),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red))
      ]);
  Future<void> open(String route) async {
    await context.push(route);
  }
}

class DiscoverView extends StatefulWidget {
  final ExpansionRepository repository;
  const DiscoverView({super.key, required this.repository});
  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends SessionState<DiscoverView> {
  @override
  ExpansionRepository get repository => widget.repository;
  final _query = TextEditingController();
  Timer? _debounce;
  String _kind = 'all', _category = 'all';
  String? _cursor;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _load();
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
    setState(() {
      _loading = true;
      error = null;
      if (!more) {
        _rows = [];
        _cursor = null;
      }
    });
    try {
      final data = await request('discover', {
        'query': _query.text.trim(),
        'kind': _kind,
        'category': _category,
        'limit': 20,
        if (more && _cursor != null) 'cursor': _cursor
      });
      if (!mounted || revision != _revision) return;
      setState(() {
        final items =
            (data['results'] as List).map((r) => Map<String, dynamic>.from(r));
        _rows = [
          if (more) ..._rows,
          ...items.where((r) =>
              !more ||
              !_rows.any(
                  (old) => old['id'] == r['id'] && old['kind'] == r['kind']))
        ];
        _cursor = data['cursor'];
      });
    } catch (e) {
      if (mounted && revision == _revision) setState(() => error = _error(e));
    } finally {
      if (mounted && revision == _revision) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const ParchAppBar(title: 'Discover', showBack: true),
      bottomNavigationBar: const ParchNavigationBar(),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text(
            'Search your groups, shared peers and the latest activities in your groups.'),
        TextButton.icon(
            onPressed: () => context.push('/people'),
            icon: const Icon(Icons.person_search_outlined),
            label: const Text('Find people by username')),
        TextField(
            controller: _query,
            decoration: const InputDecoration(
                labelText: 'Search', prefixIcon: Icon(Icons.search)),
            onChanged: (_) {
              _revision++;
              _debounce?.cancel();
              _debounce =
                  Timer(const Duration(milliseconds: 300), () => _load());
            }),
        Wrap(spacing: 8, children: [
          for (final kind in ['all', 'groups', 'activities', 'people'])
            ChoiceChip(
                label: Text(kind),
                selected: _kind == kind,
                onSelected: (_) {
                  _debounce?.cancel();
                  setState(() => _kind = kind);
                  _load();
                })
        ]),
        DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['all', 'study', 'social', 'sports', 'living', 'other']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (c) {
              setState(() => _category = c!);
              _load();
            }),
        TextButton(
            onPressed: () {
              _debounce?.cancel();
              _query.clear();
              setState(() {
                _kind = 'all';
                _category = 'all';
              });
              _load();
            },
            child: const Text('Clear search and filters')),
        if (_loading) const LinearProgressIndicator(),
        feedback(),
        if (error != null)
          TextButton(
              onPressed: () => _load(), child: const Text('Retry search')),
        if (!_loading && error == null && _rows.isEmpty)
          const Text('No results for these filters.'),
        if (sameSession)
          for (final row in _rows)
            Card(
                child: ListTile(
                    title: Text(row['title']),
                    subtitle: Text('${row['kind']} · ${row['description']}'),
                    onTap: () => open(switch (row['kind']) {
                          'groups' => AppRoutes.groupDetails(row['targetId']),
                          'activities' =>
                            AppRoutes.studySession(row['targetId']),
                          _ => '/people/${Uri.encodeComponent(row['targetId'])}'
                        }))),
        if (_cursor != null)
          TextButton(
              onPressed: _loading ? null : () => _load(more: true),
              child: const Text('Load more')),
        TextButton(
            onPressed: () => open('/join'),
            child: const Text('Open an invitation code or link')),
      ]));
}

class SharedProfileView extends StatefulWidget {
  final ExpansionRepository repository;
  final String userId;
  const SharedProfileView(
      {super.key, required this.repository, required this.userId});
  @override
  State<SharedProfileView> createState() => _SharedProfileViewState();
}

class _SharedProfileViewState extends SessionState<SharedProfileView> {
  @override
  ExpansionRepository get repository => widget.repository;
  Map<String, dynamic>? _profile;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => action(() async {
        final p = await request('getSharedProfile', {'userId': widget.userId});
        if (mounted) setState(() => _profile = p);
      });
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const ParchAppBar(title: 'Shared profile', showBack: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        feedback(),
        if (_profile != null && sameSession)
          Text(_profile!['name'],
              style: Theme.of(context).textTheme.headlineMedium),
        const Text(
            'Identity visible through your shared groups. No connection request has been sent.'),
        if (error != null)
          TextButton(onPressed: busy ? null : _load, child: const Text('Retry'))
      ]));
}

class ShareEntityView extends StatefulWidget {
  final ExpansionRepository repository;
  final ExternalActions external;
  final String kind, entityId;
  const ShareEntityView(
      {super.key,
      required this.repository,
      required this.external,
      required this.kind,
      required this.entityId});
  @override
  State<ShareEntityView> createState() => _ShareEntityViewState();
}

class _ShareEntityViewState extends SessionState<ShareEntityView> {
  @override
  ExpansionRepository get repository => widget.repository;
  String _requestId = _key();
  Map<String, dynamic>? _link;
  List<dynamic> _links = [];
  String? _message;
  Future<void> _create() => action(() async {
        final link = await request('createShareLink', {
          'requestId': _requestId,
          'kind': widget.kind,
          'entityId': widget.entityId,
          'hours': 24,
          'clientUserId': repository.sessionId
        });
        if (mounted) setState(() => _link = link);
        await _list();
      });
  Future<void> _list() async {
    final data = await request('getShareLinks', {'entityId': widget.entityId});
    if (mounted) setState(() => _links = data['links']);
  }

  @override
  void initState() {
    super.initState();
    action(_list);
  }

  Future<void> _copy(String value) => action(() async {
        _message = null;
        await widget.external.copy(value);
        if (mounted) setState(() => _message = 'Copied to clipboard.');
      });
  @override
  Widget build(BuildContext context) {
    final link = sameSession ? _link : null;
    final url =
        link == null ? null : widget.external.enrollmentUrl(link['token']);
    return Scaffold(
        appBar: const ParchAppBar(title: 'Share', showBack: true),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          feedback(),
          Text(widget.kind == 'group'
              ? 'Anyone with this code can request to join by confirming. It expires in 24 hours and can be revoked.'
              : 'This link preserves existing group permissions. It does not grant access to private activities or profiles.'),
          if (link == null)
            FilledButton(
                onPressed: busy ? null : _create,
                child: const Text('Create share code')),
          if (link != null) ...[
            Text('Expires: ${link['expiresAt']}'),
            SelectableText(url ?? link['token']),
            if (url == null)
              const Text(
                  'A web app base URL is not configured on this device. Share the code and open it through Discover → Open an invitation code or link. No public URL or QR is claimed.'),
            if (url != null)
              Center(
                  child: QrImageView(
                      data: url,
                      semanticsLabel: 'Share link QR: $url',
                      size: 220,
                      backgroundColor: Colors.white)),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                  onPressed: busy ? null : () => _copy(url ?? link['token']),
                  child: const Text('Copy')),
              FilledButton(
                  onPressed: busy
                      ? null
                      : () => action(() async {
                            final message = await widget.external.shareText(
                                url ?? 'ParchApp code: ${link['token']}');
                            if (mounted) setState(() => _message = message);
                          }),
                  child: const Text('Share'))
            ]),
            const Text(
                'Opening a share sheet is not proof of an email or invitation delivery.'),
          ],
          if (_message != null) Text(_message!),
          const SizedBox(height: 20),
          Text('Your links for this entity',
              style: Theme.of(context).textTheme.titleLarge),
          if (sameSession)
            for (final item in _links)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item['kind']} · ${item['state']}'),
                  subtitle: Text('Expires: ${item['expiresAt']}'),
                  trailing: item['state'] == 'active'
                      ? TextButton(
                          onPressed: busy
                              ? null
                              : () => action(() async {
                                    await request('revokeShareLink', {
                                      'linkId': item['linkId'],
                                      'clientUserId': repository.sessionId
                                    });
                                    if (_link?['linkId'] == item['linkId']) {
                                      setState(() {
                                        _link = null;
                                        _requestId = _key();
                                        _message = null;
                                      });
                                    }
                                    await _list();
                                  }),
                          child: const Text('Revoke'))
                      : null),
          if (error != null)
            TextButton(
                onPressed: busy ? null : () => action(_list),
                child: const Text('Retry list')),
        ]));
  }
}

class JoinLinkView extends StatefulWidget {
  final ExpansionRepository repository;
  final String? token;
  const JoinLinkView({super.key, required this.repository, this.token});
  @override
  State<JoinLinkView> createState() => _JoinLinkViewState();
}

class _JoinLinkViewState extends SessionState<JoinLinkView> {
  @override
  ExpansionRepository get repository => widget.repository;
  late final _token = TextEditingController(text: widget.token);
  Map<String, dynamic>? _preview;
  String? _resolvedToken;
  @override
  void initState() {
    super.initState();
    if (widget.token != null) _resolve();
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  String _code() {
    final raw = _token.text.trim().replaceFirst('ParchApp code: ', '');
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      final route = uri.fragment.isNotEmpty ? Uri.parse(uri.fragment) : uri;
      return route.pathSegments.last;
    }
    return raw;
  }

  Future<void> _resolve() => action(() async {
        final code = _code();
        final p = await request('resolveShareLink', {'token': code});
        if (mounted) {
          setState(() {
            _preview = p;
            _resolvedToken = code;
          });
        }
      });
  Future<void> _proceed() => action(() async {
        final p = _preview!;
        if (p['kind'] == 'group' && p['member'] != true) {
          final receipt = await request('joinSharedGroup',
              {'token': _resolvedToken, 'clientUserId': repository.sessionId});
          if (mounted) context.go(AppRoutes.groupDetails(receipt['groupId']));
        } else if (mounted) {
          context.go(switch (p['kind']) {
            'group' => AppRoutes.groupDetails(p['entityId']),
            'activity' => AppRoutes.studySession(p['entityId']),
            _ => '/people/${Uri.encodeComponent(p['entityId'])}'
          });
        }
      });
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const ParchAppBar(title: 'Open shared link', showBack: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        feedback(),
        TextField(
            controller: _token,
            enabled: !busy,
            decoration:
                const InputDecoration(labelText: 'Invitation code or app link'),
            onChanged: (_) => setState(() => _preview = null)),
        FilledButton(
            onPressed: busy ? null : _resolve,
            child: const Text('Review link')),
        if (_preview != null && sameSession) ...[
          Text(_preview!['title'],
              style: Theme.of(context).textTheme.headlineSmall),
          Text('Expires: ${_preview!['expiresAt']}'),
          FilledButton(
              onPressed: busy ? null : _proceed,
              child: Text(
                  _preview!['kind'] == 'group' && _preview!['member'] != true
                      ? 'Confirm joining group'
                      : 'Open details'))
        ],
      ]));
}

class CalendarStatusView extends StatefulWidget {
  final ExpansionRepository repository;
  final Future<void> Function() importCalendar;
  final bool canImport;
  const CalendarStatusView(
      {super.key,
      required this.repository,
      required this.importCalendar,
      this.canImport = true});
  @override
  State<CalendarStatusView> createState() => _CalendarStatusViewState();
}

class _CalendarStatusViewState extends SessionState<CalendarStatusView> {
  @override
  ExpansionRepository get repository => widget.repository;
  Map<String, dynamic>? _status;
  @override
  void initState() {
    super.initState();
    action(_load);
  }

  Future<void> _load() async {
    final data = await request('getCalendarImportStatus', {});
    if (mounted) setState(() => _status = data);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const ParchAppBar(title: 'Calendar & import', showBack: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        feedback(),
        if (!widget.canImport)
          const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                  'Google Calendar import is not configured for this build. You can still compare shared availability and export activities as calendar files.')),
        const Text(
            'Google FreeBusy import copies busy intervals. It does not export activities, sync automatically, or connect Apple/Outlook.'),
        if (_status != null && sameSession)
          Text(_status!['lastImportedAt'] == null
              ? 'No successful import recorded.'
              : 'Last successful import: ${_status!['lastImportedAt']}\n${_status!['days']} days starting ${_status!['startDate']}'),
        const Text(
            'A saved snapshot does not prove that provider authorization is still valid. Import requests consent when required. Existing data remains if import fails.'),
        FilledButton(
            onPressed: busy || !widget.canImport
                ? null
                : () => action(() async {
                      await widget.importCalendar();
                      await _load();
                    }),
            child: const Text('Authorize and import Google FreeBusy')),
        OutlinedButton(
            onPressed: busy ? null : () => action(_load),
            child: const Text('Refresh import status')),
        TextButton(
            onPressed: () => open(AppRoutes.schedule),
            child: const Text('Open Schedule')),
      ]));
}

class ActivityMaterialsView extends StatefulWidget {
  final ExpansionRepository repository;
  final ExternalActions external;
  final String activityId;
  const ActivityMaterialsView(
      {super.key,
      required this.repository,
      required this.external,
      required this.activityId});
  @override
  State<ActivityMaterialsView> createState() => _ActivityMaterialsViewState();
}

class _ActivityMaterialsViewState extends SessionState<ActivityMaterialsView> {
  @override
  ExpansionRepository get repository => widget.repository;
  Map<String, dynamic>? _data;
  final _topic = TextEditingController(),
      _resource = TextEditingController(),
      _url = TextEditingController();
  String? _message;
  @override
  void initState() {
    super.initState();
    action(_load);
  }

  @override
  void dispose() {
    _topic.dispose();
    _resource.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await request(
        'getActivityMaterials', {'activityId': widget.activityId});
    if (mounted) setState(() => _data = d);
  }

  Map<String, dynamic>? _pending;
  Future<void> _save(List<dynamic> topics, List<dynamic> resources) {
    _message = null;
    _pending ??= {
      'activityId': widget.activityId,
      'expectedVersion': _data!['version'],
      'topics': [
        for (final t in topics) {'id': t['id'], 'title': t['title']}
      ],
      'resources': resources,
      'clientUserId': repository.sessionId
    };
    return _sendMaterials();
  }

  Future<void> _sendMaterials() => action(() async {
        try {
          final result = await request('saveActivityMaterials', _pending!);
          if (mounted) {
            setState(() {
              _pending = null;
              _data = result;
              _topic.clear();
              _resource.clear();
              _url.clear();
              _message = 'Resources saved.';
            });
          }
        } catch (e) {
          if (e is FirebaseFunctionsException &&
              [
                'invalid-argument',
                'permission-denied',
                'aborted',
                'failed-precondition',
                'not-found',
                'unauthenticated'
              ].contains(e.code)) {
            _pending = null;
          }
          rethrow;
        }
      });
  @override
  Widget build(BuildContext context) {
    final data = sameSession ? _data : null;
    final topics = data?['topics'] as List? ?? [],
        resources = data?['resources'] as List? ?? [];
    return Scaffold(
        appBar:
            const ParchAppBar(title: 'Checklist & resources', showBack: true),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          feedback(),
          TextButton(
              onPressed: busy || _pending != null ? null : () => action(_load),
              child: const Text('Reload resources')),
          if (_pending != null)
            FilledButton(
                onPressed: busy ? null : _sendMaterials,
                child: const Text('Retry the same resource save')),
          if (data != null) ...[
            Text(
                '${topics.where((t) => t['completed'] == true).length}/${topics.length} personal checklist items completed'),
            for (final t in topics)
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t['title']),
                  value: t['completed'] == true,
                  onChanged: busy ||
                          _pending != null ||
                          data['cancelled'] == true
                      ? null
                      : (value) => action(() async {
                            await request('setTopicCompletion', {
                              'activityId': widget.activityId,
                              'topicId': t['id'],
                              'completed': value,
                              'clientUserId': repository.sessionId
                            });
                            if (mounted) setState(() => t['completed'] = value);
                          }),
                  secondary: data['canEdit'] == true
                      ? IconButton(
                          tooltip: 'Remove topic',
                          onPressed: busy || _pending != null
                              ? null
                              : () => _save(
                                  topics
                                      .where((x) => x['id'] != t['id'])
                                      .toList(),
                                  resources),
                          icon: const Icon(Icons.delete_outline))
                      : null),
            if (topics.isEmpty) const Text('No checklist items yet.'),
            const SizedBox(height: 16),
            Text('Organizer-provided HTTPS resources',
                style: Theme.of(context).textTheme.titleLarge),
            for (final r in resources)
              Card(
                  child: ListTile(
                      title: Text(r['title']),
                      subtitle: Text(r['url']),
                      onTap: busy
                          ? null
                          : () => action(() async {
                                if (!await widget.external
                                    .openResource(r['url'])) {
                                  throw StateError(
                                      'No application accepted this URL.');
                                }
                              }),
                      trailing: data['canEdit'] == true
                          ? IconButton(
                              tooltip: 'Remove resource',
                              onPressed: busy || _pending != null
                                  ? null
                                  : () => _save(
                                      topics,
                                      resources
                                          .where((x) => x['id'] != r['id'])
                                          .toList()),
                              icon: const Icon(Icons.delete_outline))
                          : null)),
            if (resources.isEmpty)
              const Text(
                  'No resources attached. Opening a link does not download or save a file.'),
            if (data['canEdit'] == true) ...[
              TextField(
                  controller: _topic,
                  enabled: !busy && _pending == null,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'New topic')),
              FilledButton(
                  onPressed: busy || _pending != null
                      ? null
                      : () => _save([
                            ...topics,
                            {'id': _key(), 'title': _topic.text.trim()}
                          ], resources),
                  child: const Text('Add topic')),
              TextField(
                  controller: _resource,
                  enabled: !busy && _pending == null,
                  maxLength: 120,
                  decoration:
                      const InputDecoration(labelText: 'Resource title')),
              TextField(
                  controller: _url,
                  enabled: !busy && _pending == null,
                  maxLength: 2048,
                  keyboardType: TextInputType.url,
                  decoration:
                      const InputDecoration(labelText: 'HTTPS resource URL')),
              FilledButton(
                  onPressed: busy || _pending != null
                      ? null
                      : () => _save(topics, [
                            ...resources,
                            {
                              'id': _key(),
                              'title': _resource.text.trim(),
                              'url': _url.text.trim()
                            }
                          ]),
                  child: const Text('Add HTTPS resource')),
            ],
          ],
          if (_message != null) Text(_message!),
          const Divider(),
          Text('Calendar export',
              style: Theme.of(context).textTheme.titleLarge),
          const Text(
              'Export a scheduled activity as an .ics file to import in your calendar. This does not connect or synchronize a calendar account.'),
          FilledButton(
              onPressed: busy
                  ? null
                  : () => action(() async {
                        final file = await request('exportActivityCalendar',
                            {'activityId': widget.activityId});
                        final result = await widget.external
                            .shareCalendar(file['fileName'], file['content']);
                        if (mounted) setState(() => _message = result);
                      }),
              child: const Text('Share calendar file (.ics)')),
          OutlinedButton(
              onPressed: () => open(
                  '/share/activity/${Uri.encodeComponent(widget.activityId)}'),
              child: const Text('Share activity link')),
        ]));
  }
}
