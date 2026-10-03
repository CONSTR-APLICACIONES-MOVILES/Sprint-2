import 'package:flutter/material.dart';
import '../../domain/entities/activity_draft.dart';
import '../view_models/activity_editor_view_model.dart';

/// Shared create/edit form, retaining the existing activity sheet's fields,
/// spacing and themed controls. Scheduling remains in Activity Details.
class ActivityForm extends StatefulWidget {
  final ActivityEditorViewModel viewModel;
  final ValueChanged<String> onSaved;
  const ActivityForm(
      {super.key, required this.viewModel, required this.onSaved});
  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  late final _title =
      TextEditingController(text: widget.viewModel.session?.title);
  late final _description =
      TextEditingController(text: widget.viewModel.session?.description);
  late final _location =
      TextEditingController(text: widget.viewModel.session?.location);
  late final _date = TextEditingController(
      text: widget.viewModel.session?.legacyDate ??
          widget.viewModel.requestedDate);
  late final _time = TextEditingController(
      text: widget.viewModel.session?.legacyTime ??
          widget.viewModel.requestedTime);
  late String _category = widget.viewModel.session?.category ?? 'study';
  late String _status = widget.viewModel.session?.status ?? 'PROPOSED';
  String? _groupId;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    for (final controller in [_title, _description, _location, _date, _time]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final session = widget.viewModel.session;
    final groups = widget.viewModel.value.groups;
    final id = await widget.viewModel.save(ActivityDraft(
        groupId: session?.groupId ??
            _groupId ??
            (groups.length == 1 ? groups.single.id : ''),
        title: _title.text,
        description: _description.text,
        category: _category,
        location: _location.text,
        status: _status,
        date: _date.text,
        time: _time.text));
    if (mounted && id != null) widget.onSaved(id);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<
          ActivityEditorState>(
      valueListenable: widget.viewModel,
      builder: (context, state, _) {
        final editing = widget.viewModel.session != null;
        final scheduled = widget.viewModel.session?.startsAt != null;
        final blocked = state.saving || state.loading;
        return PopScope(
            canPop: !state.saving,
            child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          editing
                              ? 'Modify Activity Details'
                              : 'Create New Activity',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      if (state.loading) const LinearProgressIndicator(),
                      if (!editing &&
                          !state.loading &&
                          state.groups.isEmpty) ...[
                        Text(state.error ??
                            'You need to belong to a group before creating an activity.'),
                        TextButton(
                            onPressed: blocked ? null : widget.viewModel.load,
                            child: const Text('Reload groups')),
                      ],
                      if (!editing && state.groups.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                            initialValue: _groupId ??
                                (state.groups.length == 1
                                    ? state.groups.single.id
                                    : null),
                            decoration:
                                const InputDecoration(labelText: 'Group'),
                            items: [
                              for (final group in state.groups)
                                DropdownMenuItem(
                                    value: group.id, child: Text(group.name))
                            ],
                            onChanged: blocked
                                ? null
                                : (value) => setState(() => _groupId = value)),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                          controller: _title,
                          enabled: !blocked,
                          maxLength: 120,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                              labelText: 'Activity name')),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _description,
                          enabled: !blocked,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: 5000,
                          decoration:
                              const InputDecoration(labelText: 'Description')),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _location,
                          enabled: !blocked,
                          decoration:
                              const InputDecoration(labelText: 'Location')),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: [
                            for (final name in [
                              'study',
                              'sports',
                              'social',
                              'other'
                            ])
                              DropdownMenuItem(value: name, child: Text(name))
                          ],
                          onChanged: blocked
                              ? null
                              : (value) => setState(() => _category = value!)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(
                                value: 'PROPOSED', child: Text('Proposed')),
                            DropdownMenuItem(
                                value: 'CONFIRMED', child: Text('Confirmed'))
                          ],
                          onChanged: blocked
                              ? null
                              : (value) => setState(() => _status = value!)),
                      const SizedBox(height: 16),
                      if (!scheduled) ...[
                        TextField(
                            controller: _date,
                            enabled: !blocked,
                            decoration: const InputDecoration(
                                labelText: 'Requested date (optional)')),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _time,
                            enabled: !blocked,
                            decoration: const InputDecoration(
                                labelText: 'Requested time (optional)')),
                        const SizedBox(height: 12),
                      ],
                      const Text(
                          'Choose or change the scheduled time using recommendations in Activity Details.'),
                      if (state.error != null) ...[
                        const SizedBox(height: 16),
                        Text(state.error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                          onPressed:
                              blocked || (!editing && state.groups.isEmpty)
                                  ? null
                                  : _save,
                          child: Text(state.saving
                              ? 'Saving…'
                              : editing
                                  ? 'Save Changes'
                                  : 'Create Activity')),
                      if (editing)
                        TextButton(
                            onPressed: state.saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Dismiss')),
                    ])));
      });
}
