import 'package:flutter/material.dart';
import '../../../../shared/widgets/inline_error_notice.dart';

class PasswordRecoverySheet extends StatefulWidget {
  final String email;
  final Future<void> Function(String) request;
  const PasswordRecoverySheet(
      {super.key, required this.email, required this.request});
  @override
  State<PasswordRecoverySheet> createState() => _PasswordRecoverySheetState();
}

class _PasswordRecoverySheetState extends State<PasswordRecoverySheet> {
  late final _email = TextEditingController(text: widget.email);
  bool _busy = false, _acknowledged = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.request(email);
      if (mounted) setState(() => _acknowledged = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Recovery request failed. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Text('Reset password',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            if (_acknowledged) ...[
              const Text(
                  'Request accepted. If an account uses this email, follow the recovery instructions. Check spam too.',
                  style: TextStyle(height: 1.6)),
              const SizedBox(height: 18),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'))
            ] else ...[
              TextField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email')),
              if (_error != null) InlineErrorNotice(_error!),
              const SizedBox(height: 18),
              FilledButton(
                  onPressed: _busy ? null : _send,
                  child: Text(_busy ? 'Requesting…' : 'Request password reset'))
            ],
          ])));
}
