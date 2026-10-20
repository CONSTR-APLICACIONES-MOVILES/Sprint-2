import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/entities/profile_preferences.dart';

const visibilityLabels = {
  'groups': 'Shared group members',
  'closeFriends': 'Close friends',
  'private': 'Only me'
};

class PresenceSheet extends StatefulWidget {
  final ProfileUser user;
  final Future<bool> Function(AvailabilityStatus, DateTime, String) onSave;
  const PresenceSheet({super.key, required this.user, required this.onSave});
  @override
  State<PresenceSheet> createState() => _PresenceSheetState();
}

class _PresenceSheetState extends State<PresenceSheet> {
  late AvailabilityStatus _status = widget.user.effectiveStatus;
  late String _scope = widget.user.preferences.statusVisibility;
  int _minutes = 60;
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    bool saved = false;
    try {
      saved = await widget.onSave(_status,
          DateTime.now().toUtc().add(Duration(minutes: _minutes)), _scope);
    } catch (_) {}
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error =
          'Unable to save status. Your choices are preserved. Retry when connected.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                        color: AppColors.blueTint,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('PARCHAPP STATUS',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)))),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Expanded(
                  child: Text("What's your status right now?",
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w800))),
              IconButton(
                  tooltip: 'Close status',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20))
            ]),
            const Text(
                "Your friends and groups will see the status you choose, according to your privacy settings.",
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 18),
            for (final status in [
              AvailabilityStatus.active,
              AvailabilityStatus.inClass,
              AvailabilityStatus.focused,
              AvailabilityStatus.busy,
              AvailabilityStatus.inTransit,
              AvailabilityStatus.offline
            ])
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _statusCard(status)),
            const SizedBox(height: 8),
            const Text('STATUS DURATION',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                    color: AppColors.textSecondary)),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final minutes in [15, 30, 60, 120, 240, 480])
                ChoiceChip(
                    label: Text(minutes < 60
                        ? '$minutes min'
                        : '${minutes ~/ 60} hour${minutes == 60 ? '' : 's'}'),
                    selected: _minutes == minutes,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: _minutes == minutes
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _minutes = minutes))
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _scope,
                decoration: const InputDecoration(labelText: 'Visible to'),
                items: visibilityLabels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: _saving ? null : (s) => setState(() => _scope = s!)),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error))),
            const SizedBox(height: 16),
            FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.bolt),
                label: Text(_saving ? 'Saving…' : 'Save status')),
            const SizedBox(height: 10),
            const Text(
                'Privacy: calendar events and location remain private. Status expires to Offline; it does not update your calendar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]));

  Widget _statusCard(AvailabilityStatus status) {
    final (icon, color, title, detail, tag) = switch (status) {
      AvailabilityStatus.active => (
          Icons.check_circle,
          AppColors.success,
          'Available',
          'Free to study, grab coffee, or hang out',
          'Ready to hang out'
        ),
      AvailabilityStatus.inClass => (
          Icons.school,
          const Color(0xFFA55C11),
          'In Class / Lab',
          'Attending a lecture or lab',
          'In class'
        ),
      AvailabilityStatus.focused => (
          Icons.menu_book,
          const Color(0xFF5345D8),
          'Library / Focus',
          'Focused study or collaborative work',
          'Focus'
        ),
      AvailabilityStatus.busy => (
          Icons.do_not_disturb_on,
          const Color(0xFFCE1746),
          'Busy',
          'Deadlines, exams, or personal commitments',
          'Do not disturb'
        ),
      AvailabilityStatus.inTransit => (
          Icons.train,
          const Color(0xFF087AA5),
          'In Transit / Commute',
          'Commuting to or from campus',
          'In transit'
        ),
      AvailabilityStatus.offline => (
          Icons.nights_stay_outlined,
          AppColors.textSecondary,
          'Offline',
          'Not available for plans right now',
          'Offline'
        ),
    };
    final selected = _status == status;
    return Semantics(
        selected: selected,
        button: true,
        child: Material(
            color: selected ? color.withValues(alpha: .045) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _saving ? null : () => setState(() => _status = status),
                child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: selected ? color : AppColors.outlineSoft,
                            width: selected ? 1.8 : 1.3)),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: color.withValues(
                                      alpha: selected ? 1 : .10),
                                  borderRadius: BorderRadius.circular(14)),
                              child: Icon(icon,
                                  color: selected ? Colors.white : color)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(title,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700)),
                                      if (selected)
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: color.withValues(
                                                    alpha: .10),
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            child: Text(tag,
                                                style: TextStyle(
                                                    color: color,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600)))
                                    ]),
                                const SizedBox(height: 3),
                                Text(detail,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary))
                              ])),
                          const SizedBox(width: 8),
                          Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selected ? color : AppColors.border,
                              size: 23)
                        ])))));
  }
}

class PrivacySettingsSheet extends StatefulWidget {
  final ProfileUser user;
  final Future<List<Map<String, dynamic>>> Function() getPeers;
  final Future<bool> Function(ProfilePreferences) onSave;
  const PrivacySettingsSheet(
      {super.key,
      required this.user,
      required this.getPeers,
      required this.onSave});
  @override
  State<PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends State<PrivacySettingsSheet> {
  late String _status = widget.user.preferences.statusVisibility,
      _schedule = widget.user.preferences.scheduleVisibility;
  late bool _badges = widget.user.preferences.invitationBadges;
  late final _close = widget.user.preferences.closeFriendIds.toSet();
  List<Map<String, dynamic>>? _peers;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final peers = await widget.getPeers();
      if (mounted) {
        setState(() {
          _peers = peers;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load close friends. Retry.');
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    bool saved = false;
    try {
      saved = await widget.onSave(ProfilePreferences(
          statusVisibility: _status,
          scheduleVisibility: _schedule,
          closeFriendIds: _close.toList(),
          invitationBadges: _badges));
    } catch (_) {}
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = 'Unable to save settings. Your choices are preserved for retry.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Privacy & preferences',
                style: Theme.of(context).textTheme.titleLarge),
            const Text(
                'These rules apply to group members. Calendar sharing exposes busy intervals, never event titles. Calendar import is managed separately in Schedule.'),
            _scope('Status visibility', _status, (v) => _status = v),
            _scope('Calendar availability', _schedule, (v) => _schedule = v),
            const SizedBox(height: 16),
            Text('Close friends',
                style: Theme.of(context).textTheme.titleMedium),
            const Text(
                'Only selected shared peers see information set to Close friends.'),
            if (_peers == null && _error == null)
              const LinearProgressIndicator(),
            if (_peers?.isEmpty == true) const Text('No shared peers yet.'),
            for (final p in _peers ?? <Map<String, dynamic>>[])
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p['name']),
                  value: _close.contains(p['id']),
                  onChanged: _saving
                      ? null
                      : (v) => setState(() {
                            v == true
                                ? _close.add(p['id'])
                                : _close.remove(p['id']);
                          })),
            for (final id in _close
                .where((id) =>
                    _peers != null && !_peers!.any((p) => p['id'] == id))
                .toList())
              CheckboxListTile(
                  title: Text('No longer a shared peer: $id'),
                  value: true,
                  onChanged: _saving
                      ? null
                      : (_) => setState(() => _close.remove(id))),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Invitation badges on Home'),
                subtitle: const Text(
                    'Your invitation inbox remains available when badges are off.'),
                value: _badges,
                onChanged: _saving ? null : (v) => setState(() => _badges = v)),
            if (_error != null) ...[
              Text(_error!),
              if (_peers == null)
                TextButton(onPressed: _load, child: const Text('Retry'))
            ],
            FilledButton(
                onPressed: _saving || _peers == null ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save settings')),
          ]));
  Widget _scope(String label, String value, ValueChanged<String> change) =>
      DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: visibilityLabels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: _saving ? null : (v) => setState(() => change(v!)));
}
