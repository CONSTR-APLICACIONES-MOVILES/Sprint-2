import 'package:flutter/material.dart';
import '../../domain/entities/quick_status.dart';

class QuickStatusSheet extends StatefulWidget {
  final QuickStatus initial;
  final Future<void> Function(String, String) onSave;
  const QuickStatusSheet(
      {super.key, required this.initial, required this.onSave});
  @override
  State<QuickStatusSheet> createState() => _QuickStatusSheetState();
}

class _QuickStatusSheetState extends State<QuickStatusSheet> {
  late final _free = TextEditingController(text: widget.initial.freeUntil);
  late final _next = TextEditingController(text: widget.initial.nextActivity);
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_free.text, _next.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Unable to save. Your choices are preserved; try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Quick Status',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'Saved on this device. Blank fields keep your previous values. Your real activities take priority.'),
            TextField(
                controller: _free,
                enabled: !_saving,
                maxLength: 40,
                decoration: const InputDecoration(
                    labelText: 'Free until', hintText: '4:00 PM')),
            Wrap(spacing: 8, children: [
              for (final time in ['3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM'])
                ActionChip(
                    label: Text(time),
                    onPressed: _saving
                        ? null
                        : () => setState(() => _free.text = time))
            ]),
            TextField(
                controller: _next,
                enabled: !_saving,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Next activity')),
            Wrap(spacing: 8, children: [
              for (final activity in ['Library Study', 'Linear Algebra', 'Gym'])
                ActionChip(
                    label: Text(activity),
                    onPressed: _saving
                        ? null
                        : () => setState(() => _next.text = activity))
            ]),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save quick status')),
            TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
          ]));
  @override
  void dispose() {
    _free.dispose();
    _next.dispose();
    super.dispose();
  }
}
