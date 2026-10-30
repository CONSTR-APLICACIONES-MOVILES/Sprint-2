import 'package:flutter/material.dart';
import '../../core/data/offline_mobile_api.dart';

class PendingInvitationsPanel extends StatefulWidget {
  final OfflineMobileApi api;
  const PendingInvitationsPanel({super.key, required this.api});
  @override
  State<PendingInvitationsPanel> createState() =>
      _PendingInvitationsPanelState();
}

class _PendingInvitationsPanelState extends State<PendingInvitationsPanel> {
  late Future<List<PendingInvitation>> items;
  String? confirmId, error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    items = widget.api.pendingInvitations();
    widget.api.addListener(_reload);
  }

  void _reload() {
    if (mounted) {
      final next = widget.api.pendingInvitations();
      setState(() {
        items = next;
      });
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      if (mounted) setState(() => confirmId = null);
    } catch (_) {
      if (mounted) {
        setState(
            () => error = 'Unable to update saved responses. Please retry.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        _reload();
      }
    }
  }

  @override
  void dispose() {
    widget.api.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFEAF1FF),
        child: SizedBox(
            height: 210,
            child: FutureBuilder<List<PendingInvitation>>(
              future: items,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Saved responses could not be read.'));
                }
                final pending = snapshot.data;
                if (pending == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(padding: const EdgeInsets.all(12), children: [
                  const Text('Pending invitations',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text(
                      'Discard removes only your local response. Reconnect to see the server response.',
                      style: TextStyle(fontSize: 12)),
                  if (error != null) Text(error!),
                  if (pending.isEmpty)
                    const Text('No invitation responses pending.'),
                  for (final item in pending)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(confirmId == item.id
                          ? 'Discard this local response? Other responses will be kept.'
                          : '${item.response} · ${item.blocked ? 'Needs review' : 'Waiting to sync'}'),
                      trailing: Wrap(children: [
                        if (confirmId == item.id) ...[
                          TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _act(() =>
                                      widget.api.discardInvitation(item.id)),
                              child: const Text('Discard')),
                          TextButton(
                              onPressed: busy
                                  ? null
                                  : () => setState(() => confirmId = null),
                              child: const Text('Cancel')),
                        ] else ...[
                          IconButton(
                              tooltip: 'Retry this invitation',
                              onPressed: busy ||
                                      widget.api.value.syncing ||
                                      widget.api.value.offline
                                  ? null
                                  : () => _act(() =>
                                      widget.api.flush(invitationId: item.id)),
                              icon: const Icon(Icons.sync)),
                          IconButton(
                              tooltip: 'Discard this local response',
                              onPressed: busy || widget.api.value.syncing
                                  ? null
                                  : () => setState(() => confirmId = item.id),
                              icon: const Icon(Icons.delete_outline)),
                        ],
                      ]),
                    ),
                ]);
              },
            )),
      );
}
