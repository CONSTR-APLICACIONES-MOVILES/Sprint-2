import 'package:flutter/material.dart';
import '../../domain/entities/slot_recommendation.dart';
import '../view_models/study_session_view_model.dart';
import 'session_card.dart';

class RecommendedSlotsCard extends StatefulWidget {
  final StudySessionState state;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final void Function(int) onSearch;
  final VoidCallback onChangeDuration;
  final VoidCallback onRetryAnalytics;
  final void Function(String) onAccept;
  final void Function(String) onModify;
  final void Function(String, String) onShown;

  const RecommendedSlotsCard(
      {super.key,
      required this.state,
      required this.scrollController,
      required this.onRetry,
      required this.onSearch,
      required this.onChangeDuration,
      required this.onRetryAnalytics,
      required this.onAccept,
      required this.onModify,
      required this.onShown});

  @override
  State<RecommendedSlotsCard> createState() => _RecommendedSlotsCardState();
}

class _RecommendedSlotsCardState extends State<RecommendedSlotsCard> {
  final Map<String, GlobalKey> _markers = {};
  final Set<String> _reported = {};
  late final _duration = TextEditingController(
      text: widget.state.session?.durationMinutes?.toString() ?? '');
  String? _durationError;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_checkVisibility);
  }

  @override
  void didUpdateWidget(covariant RecommendedSlotsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_checkVisibility);
      widget.scrollController.addListener(_checkVisibility);
    }
    if (oldWidget.state.recommendations?.id !=
        widget.state.recommendations?.id) {
      _reported.clear();
      _markers.clear();
    }
  }

  void _checkVisibility() {
    if (!mounted ||
        widget.state.saving ||
        widget.state.selectionSaved ||
        ModalRoute.of(context)?.isCurrent == false ||
        widget.state.recommendationsStatus != RecommendationsStatus.ready) {
      return;
    }
    final batch = widget.state.recommendations!;
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;
    final visible = viewport.localToGlobal(Offset.zero) & viewport.size;
    for (final slot in batch.slots) {
      final marker = _markers[slot.id]?.currentContext?.findRenderObject();
      if (marker is RenderBox &&
          marker.hasSize &&
          visible.contains(
              marker.localToGlobal(marker.size.center(Offset.zero))) &&
          _reported.add(slot.id)) {
        widget.onShown(batch.id, slot.id);
      }
    }
  }

  @override
  void dispose() {
    _duration.dispose();
    widget.scrollController.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    final state = widget.state;
    return SessionCard(
        title: 'Recommended times',
        icon: Icons.auto_awesome,
        child: switch (state.recommendationsStatus) {
          RecommendationsStatus.idle =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text(
                  'Find times for today in Bogotá using the group’s availability and preferences.'),
              const SizedBox(height: 12),
              TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Duration in minutes (15–720)',
                      errorText: _durationError)),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: () {
                    final minutes = int.tryParse(_duration.text.trim());
                    if (minutes == null || minutes < 15 || minutes > 720) {
                      setState(() => _durationError =
                          'Enter a duration from 15 to 720 minutes.');
                      return;
                    }
                    setState(() => _durationError = null);
                    widget.onSearch(minutes);
                  },
                  child: const Text('Find times for today')),
            ]),
          RecommendationsStatus.loading => const LinearProgressIndicator(),
          RecommendationsStatus.error => Column(children: [
              Text(state.recommendationsError ??
                  'Unable to load recommended times.'),
              TextButton(
                  onPressed: widget.onRetry,
                  child: const Text('Retry recommendations')),
              TextButton(
                  onPressed: widget.onChangeDuration,
                  child: const Text('Change duration')),
            ]),
          RecommendationsStatus.empty => Column(children: [
              const Text('No recommended times are available today.'),
              TextButton(
                  onPressed: widget.onRetry,
                  child: const Text('Refresh recommendations')),
              TextButton(
                  onPressed: widget.onChangeDuration,
                  child: const Text('Change duration')),
            ]),
          RecommendationsStatus.ready =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (state.selectionSaved) const Text('Selected time saved.'),
              if (state.recommendations!.date != null)
                Text('${state.recommendations!.date} · Bogotá (UTC−05:00)'),
              for (var index = 0;
                  index < state.recommendations!.slots.length;
                  index++)
                _slot(context, state.recommendations!.slots[index], index),
              if (state.analyticsError != null) ...[
                Text(state.analyticsError!),
                TextButton(
                    onPressed: widget.onRetryAnalytics,
                    child: const Text('Retry feedback')),
              ],
              TextButton(
                  onPressed:
                      state.saving || state.refreshing ? null : widget.onRetry,
                  child: const Text('Refresh recommendations')),
              TextButton(
                  onPressed: state.saving || state.refreshing
                      ? null
                      : widget.onChangeDuration,
                  child: const Text('Change duration')),
            ]),
        });
  }

  Widget _slot(BuildContext context, RecommendedSlot slot, int index) {
    final state = widget.state;
    final disabled = state.saving ||
        state.refreshing ||
        state.selectionSaved ||
        state.session!.cancelled ||
        !state.session!.canOrganize;
    final start = state.session!.displayTime(slot.startsAt);
    final end = state.session!.displayTime(slot.endsAt);
    final localizations = MaterialLocalizations.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (index > 0) const Divider(),
          Text(index == 0 ? 'Best recommended slot' : 'Alternative $index',
              style: Theme.of(context).textTheme.titleSmall),
          Text(
              '${localizations.formatMediumDate(start)} · ${TimeOfDay.fromDateTime(start).format(context)}'
              ' – ${localizations.formatMediumDate(end)} · ${TimeOfDay.fromDateTime(end).format(context)}',
              key: _markers.putIfAbsent(slot.id, GlobalKey.new)),
          Text(
              '${slot.availableParticipants} / ${slot.totalParticipants} participants available'),
          for (final reason in slot.reasons) Text(reason),
          if (state.session!.canOrganize)
            Wrap(spacing: 8, children: [
              FilledButton(
                  onPressed: disabled
                      ? null
                      : () {
                          widget.onShown(state.recommendations!.id, slot.id);
                          widget.onAccept(slot.id);
                        },
                  child: Text(index == 0
                      ? 'Accept recommended slot'
                      : 'Select this slot')),
              TextButton(
                  onPressed: disabled
                      ? null
                      : () {
                          widget.onShown(state.recommendations!.id, slot.id);
                          widget.onModify(slot.id);
                        },
                  child: const Text('Modify time')),
            ]),
        ]));
  }
}
