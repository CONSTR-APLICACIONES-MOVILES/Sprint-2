import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../core/data/offline_mobile_api.dart';
import 'pending_invitations_panel.dart';

class OfflineShell extends StatefulWidget {
  final OfflineMobileApi api;
  final Widget child;
  const OfflineShell({super.key, required this.api, required this.child});
  @override
  State<OfflineShell> createState() => _OfflineShellState();
}

class _OfflineShellState extends State<OfflineShell>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? subscription;
  Timer? retry;
  bool confirmDiscard = false;
  bool showPending = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final connectivity = Connectivity();
    subscription = connectivity.onConnectivityChanged.listen(_network);
    connectivity.checkConnectivity().then(_network).catchError((Object _) {});
    retry = Timer.periodic(
        const Duration(seconds: 30), (_) => widget.api.flush(automatic: true));
    widget.api.refreshSession();
  }

  void _network(List<ConnectivityResult> results) => widget.api
      .setNetworkAvailable(!results.contains(ConnectivityResult.none));
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.api.flush(automatic: true);
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    retry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _discard() async {
    if (!confirmDiscard) {
      setState(() => confirmDiscard = true);
      return;
    }
    await widget.api.discardPending();
    if (mounted) setState(() => confirmDiscard = false);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<OfflineStatus>(
      valueListenable: widget.api,
      builder: (context, state, _) => Column(children: [
            if (widget.api.currentUserId() != null)
              Material(
                  color: state.offline
                      ? const Color(0xFFFFF3D6)
                      : const Color(0xFFEAF1FF),
                  child: SafeArea(
                      bottom: false,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    confirmDiscard
                                        ? 'Discard all unsynced responses? Refresh the inbox afterwards.'
                                        : state.syncing
                                            ? 'Syncing responses…'
                                            : '${state.forced ? 'Offline mode' : state.offline ? 'Offline · saved data' : 'Online'}'
                                                '${state.pending > 0 ? ' · ${state.pending} pending' : ''}'
                                                '${state.error == null ? '' : '\n${state.error}'}',
                                    style: const TextStyle(fontSize: 12))),
                            if (state.pending > 0) ...[
                              IconButton(
                                  tooltip: 'Review pending invitations',
                                  onPressed: () => setState(
                                      () => showPending = !showPending),
                                  icon: const Icon(Icons.fact_check_outlined,
                                      size: 20)),
                              IconButton(
                                  tooltip: 'Retry synchronization',
                                  onPressed: state.syncing || state.forced
                                      ? null
                                      : widget.api.flush,
                                  icon: const Icon(Icons.sync, size: 20)),
                              if (state.error != null)
                                IconButton(
                                    tooltip: 'Discard pending responses',
                                    onPressed: _discard,
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20)),
                            ],
                            if (confirmDiscard)
                              TextButton(
                                  onPressed: _discard,
                                  child: const Text('Discard')),
                            if (confirmDiscard)
                              TextButton(
                                  onPressed: () =>
                                      setState(() => confirmDiscard = false),
                                  child: const Text('Cancel')),
                            if (!confirmDiscard)
                              TextButton(
                                  onPressed: () => widget.api
                                      .setForcedOffline(!state.forced),
                                  child: Text(state.forced
                                      ? 'Go online'
                                      : 'Use offline')),
                          ])))),
            if (showPending && widget.api.currentUserId() != null)
              PendingInvitationsPanel(
                  key: ValueKey(widget.api.currentUserId()), api: widget.api),
            Expanded(child: widget.child),
          ]));
}
