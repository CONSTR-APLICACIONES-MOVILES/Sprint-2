import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_routes.dart';
import 'parch_navigation_bar.dart';

/// A registered destination for modules that do not yet have an implementation.
class UnavailableFeatureView extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final String? actionLabel;
  final String? actionRoute;

  const UnavailableFeatureView({
    super.key,
    required this.title,
    required this.selectedIndex,
    this.actionLabel,
    this.actionRoute,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.construction_outlined, size: 48),
            const SizedBox(height: 16),
            Text('$title is coming soon.',
                style: Theme.of(context).textTheme.titleLarge),
            if (actionLabel != null && actionRoute != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(actionRoute!),
                icon: const Icon(Icons.groups_2_outlined, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Back to Home')),
          ]),
        ))),
        bottomNavigationBar: ParchNavigationBar(selectedIndex: selectedIndex),
      );
}