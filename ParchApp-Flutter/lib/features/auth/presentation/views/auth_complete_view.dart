import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';

/// Temporary destination while the Home feature is still unimplemented.
class AuthCompleteView extends StatelessWidget {
  const AuthCompleteView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Authentication successful')),
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Home will be implemented next.'),
          FilledButton.icon(
              onPressed: () => context.push(AppRoutes.alerts),
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Open Alerts')),
          TextButton(
              onPressed: () => context.go(AppRoutes.welcome),
              child: const Text('Back to welcome')),
        ])),
      );
}
