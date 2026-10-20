import 'package:flutter/material.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../view_models/study_session_view_model.dart';
import '../widgets/recommended_slots_card.dart';
import '../widgets/edit_session_sheet.dart';

class SuggestedTimesView extends StatefulWidget {
  final StudySessionViewModel viewModel;
  const SuggestedTimesView({super.key, required this.viewModel});
  @override
  State<SuggestedTimesView> createState() => _SuggestedTimesViewState();
}

class _SuggestedTimesViewState extends State<SuggestedTimesView> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<StudySessionState>(
          valueListenable: widget.viewModel,
          builder: (context, state, _) => Scaffold(
              appBar:
                  const ParchAppBar(title: 'Suggested Times', showBack: true),
              body: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                        'Suggestions use today in Bogotá. Order and reasons come from the server and respect calendar privacy. No availability is assumed when data is missing.'),
                    if (state.status == SessionLoadStatus.loading)
                      const LinearProgressIndicator(),
                    if (state.error != null) Text(state.error!),
                    if (state.session == null &&
                        state.status != SessionLoadStatus.loading)
                      TextButton(
                          onPressed: widget.viewModel.load,
                          child: const Text('Retry activity')),
                    if (state.session != null && !state.session!.canOrganize)
                      const Text(
                          'Only the organizer can request or choose suggested times.'),
                    if (state.session?.canOrganize == true)
                      RecommendedSlotsCard(
                          showTimeFilters: true,
                          state: state,
                          scrollController: _scroll,
                          onRetry: () => widget.viewModel.loadRecommendations(),
                          onSearch: (minutes) => widget.viewModel
                              .loadRecommendations(durationMinutes: minutes),
                          onChangeDuration:
                              widget.viewModel.changeRecommendationDuration,
                          onRetryAnalytics: widget.viewModel.retryAnalytics,
                          onShown: widget.viewModel.recommendationShown,
                          onAccept: widget.viewModel.acceptSlot,
                          onModify: (id) {
                            final slot = state.recommendations!.getSlot(id);
                            showModalBottomSheet<void>(
                                context: context,
                                useSafeArea: true,
                                isScrollControlled: true,
                                builder: (_) => EditSessionSheet(
                                    session: state.session!.copyWith(
                                        startsAt: slot.startsAt,
                                        endsAt: slot.endsAt),
                                    onSave: (draft) async {
                                      final saved = await widget.viewModel
                                          .update(
                                              title: draft.title,
                                              room: draft.room,
                                              startsAt: draft.startsAt,
                                              endsAt: draft.endsAt,
                                              sourceSlotId: id);
                                      return saved
                                          ? null
                                          : widget.viewModel.value.error ??
                                              'Unable to change this time.';
                                    }));
                          }),
                  ])));
}
