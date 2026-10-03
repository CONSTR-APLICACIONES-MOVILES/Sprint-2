import 'package:flutter/material.dart';
import '../../domain/entities/study_session.dart';

class SessionDraft {
  final String title;
  final String room;
  final DateTime startsAt;
  final DateTime endsAt;
  const SessionDraft(this.title, this.room, this.startsAt, this.endsAt);
}

class EditSessionSheet extends StatefulWidget {
  final StudySession session;
  final Future<String?> Function(SessionDraft) onSave;
  const EditSessionSheet(
      {super.key, required this.session, required this.onSave});
  @override
  State<EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends State<EditSessionSheet> {
  late final _title = TextEditingController(text: widget.session.title);
  late final _room = TextEditingController(text: widget.session.room);
  late DateTime _start = widget.session.displayTime(widget.session.startsAt!);
  late DateTime _end = widget.session.displayTime(widget.session.endsAt!);
  bool _saving = false;
  String? _error;

  Future<void> _date() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _start,
        firstDate: DateTime(_start.year - 10),
        lastDate: DateTime(_start.year + 10));
    if (!mounted || date == null) return;
    setState(() {
      _start =
          DateTime(date.year, date.month, date.day, _start.hour, _start.minute);
      _end = DateTime(date.year, date.month, date.day, _end.hour, _end.minute);
    });
  }

  Future<void> _time(bool start) async {
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(start ? _start : _end));
    if (!mounted || time == null) return;
    setState(() {
      final value = DateTime(
          _start.year, _start.month, _start.day, time.hour, time.minute);
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(SessionDraft(
        _title.text,
        _room.text,
        widget.session.fromDisplayTime(_start),
        widget.session.fromDisplayTime(_end)));
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    widget.session.supportsDetailsEditing
                        ? 'Modify Session Details'
                        : 'Modify recommended time',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                if (widget.session.supportsDetailsEditing) ...[
                  TextField(
                      controller: _title,
                      enabled: !_saving,
                      decoration:
                          const InputDecoration(labelText: 'Session Title')),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _room,
                      enabled: !_saving,
                      decoration:
                          const InputDecoration(labelText: 'Location / Room')),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                    onPressed: _saving || !widget.session.supportsDetailsEditing
                        ? null
                        : _date,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(MaterialLocalizations.of(context)
                        .formatMediumDate(_start))),
                const SizedBox(height: 8),
                if (!widget.session.supportsDetailsEditing)
                  const Text(
                      'Today in Bogotá (UTC−05:00). Choose a time when everyone is available.'),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  TextButton(
                      onPressed: _saving ? null : () => _time(true),
                      child: Text(
                          'Start: ${TimeOfDay.fromDateTime(_start).format(context)}')),
                  TextButton(
                      onPressed: _saving ? null : () => _time(false),
                      child: Text(
                          'End: ${TimeOfDay.fromDateTime(_end).format(context)}')),
                ]),
                if (_error != null) ...[
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12)
                ],
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save Changes')),
                TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Dismiss')),
              ]),
        ),
      );
}
