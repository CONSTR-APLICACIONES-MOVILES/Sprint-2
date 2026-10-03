import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/entities/photo_source.dart';

Future<T?> showProfileSheet<T>(BuildContext context, {required Widget child}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SingleChildScrollView(child: child),
      ),
    );

class AvailabilitySheet extends StatelessWidget {
  final AvailabilityStatus current;
  const AvailabilitySheet({super.key, required this.current});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Change availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final status in AvailabilityStatus.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).pop(status),
              leading: Icon(Icons.circle,
                  size: 14,
                  color: status == AvailabilityStatus.active
                      ? AppColors.success
                      : AppColors.friendBusy),
              title: Text(
                  status == AvailabilityStatus.active ? 'Active' : 'Busy',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(status == AvailabilityStatus.active
                  ? 'Friends can invite you to plans'
                  : 'You will not show up as available'),
              trailing: status == current
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
            ),
        ],
      );
}

class EditProfileSheet extends StatefulWidget {
  final ProfileUser user;
  final ValueChanged<PhotoSource> onPhoto;

  const EditProfileSheet(
      {super.key, required this.user, required this.onPhoto});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _program = TextEditingController(text: widget.user.program);
  late final _campus = TextEditingController(text: widget.user.campus);
  late final _university = TextEditingController(text: widget.user.university);
  late int _semester = widget.user.semester;
  late AcademicLevel _level = widget.user.academicLevel;

  @override
  void dispose() {
    _name.dispose();
    _program.dispose();
    _campus.dispose();
    _university.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _program.text.trim().isNotEmpty;

  void _save() {
    Navigator.of(context).pop(widget.user.copyWith(
      name: _name.text.trim(),
      program: _program.text.trim(),
      campus: _campus.text.trim(),
      university: _university.text.trim(),
      semester: _semester,
      academicLevel: _level,
    ));
  }

  void _photo(PhotoSource source) {
    Navigator.of(context).pop();
    widget.onPhoto(source);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Edit profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
                    Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _photo(PhotoSource.frontCamera),
                icon: const Icon(Icons.camera_front_outlined, size: 18),
                label: const Text('Take a selfie'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _photo(PhotoSource.rearCamera),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Rear camera'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _field(_name, 'Full name'),
          const SizedBox(height: 12),
          _field(_program, 'Program'),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _semester,
            decoration: _decoration('Semester'),
            items: [
              for (var i = 1; i <= 12; i++)
                DropdownMenuItem(value: i, child: Text('Semester $i')),
            ],
            onChanged: (value) =>
                setState(() => _semester = value ?? _semester),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AcademicLevel>(
            initialValue: _level,
            decoration: _decoration('Academic level'),
            items: [
              for (final level in AcademicLevel.values)
                DropdownMenuItem(value: level, child: Text(_label(level))),
            ],
            onChanged: (value) => setState(() => _level = value ?? _level),
          ),
          const SizedBox(height: 12),
          _field(_campus, 'Campus'),
          const SizedBox(height: 12),
          _field(_university, 'University'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _valid ? _save : null,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48)),
            child: const Text('Save changes'),
          ),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
        ],
      );

  Widget _field(TextEditingController controller, String label) => TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        decoration: _decoration(label),
      );

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFE),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  String _label(AcademicLevel level) => switch (level) {
        AcademicLevel.undergraduate => 'Undergraduate',
        AcademicLevel.graduate => 'Graduate',
        AcademicLevel.master => 'Master',
        AcademicLevel.phd => 'PhD',
      };
}
