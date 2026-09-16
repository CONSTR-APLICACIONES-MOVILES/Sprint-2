import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'alert_card.dart';

Future<T?> showAlertsSheet<T>(BuildContext context, {required Widget child}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
          maxWidth: 600, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      clipBehavior: Clip.antiAlias,
      builder: (context) => SafeArea(
          top: false,
          child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
              child: child)),
    );

class QuickActivitySheet extends StatefulWidget {
  const QuickActivitySheet({super.key});
  @override
  State<QuickActivitySheet> createState() => _QuickActivitySheetState();
}

class _QuickActivitySheetState extends State<QuickActivitySheet> {
  final _title = TextEditingController(text: 'Study break with Sarah');
  String _location = 'Central Engineering Garden (Patio)';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('1-Tap Activity Creator',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          const Text('Prefilled from mutual free schedule',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          TextField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Activity Title', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule, color: AppColors.primary),
              title: Text('17:00 – 18:30'),
              subtitle: Text('Time Slot')),
          const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.people_outline, color: AppColors.primary),
              title: Text('You & Sarah J.'),
              subtitle: Text('Participants')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _location,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Location / Campus Spot',
                border: OutlineInputBorder()),
            items: [
              for (final location in [
                'Central Engineering Garden (Patio)',
                'Biblioteca Central - Piso 3 (Sala 3B)',
                'Cafetería Central / Terraza',
                'Laboratorio de Sistemas B204'
              ])
                DropdownMenuItem(
                    value: location,
                    child: Text(location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)))
            ],
            onChanged: (value) {
              if (value != null) setState(() => _location = value);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send Instant Plan Invitation',
                  textAlign: TextAlign.center)),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
        ],
      );
}

class AlertProfileSheet extends StatelessWidget {
  final bool friendRequest;
  const AlertProfileSheet({super.key, this.friendRequest = true});

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
            radius: 34,
            backgroundColor: alertsBlueTint,
            child: Text(friendRequest ? 'CM' : 'AV',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800))),
        const SizedBox(height: 16),
        Text(friendRequest ? 'Carlos Mendoza' : 'Alex Valenzuela',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Systems & Computer Engineering',
            textAlign: TextAlign.center),
        const Text('6th Semester • Universidad Nacional',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        if (friendRequest) ...[
          const Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 12,
              children: [
                Text('14\nMutual plans', textAlign: TextAlign.center),
                Text('3\nShared classes', textAlign: TextAlign.center),
                Text('98%\nPunctuality', textAlign: TextAlign.center),
              ]),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Accept Request')),
        ],
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close')),
      ]);
}
