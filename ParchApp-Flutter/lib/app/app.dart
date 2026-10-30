import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/data/offline_mobile_api.dart';
import '../shared/widgets/offline_shell.dart';

class ParchApp extends StatelessWidget {
  final GoRouter router;
  final OfflineMobileApi? offline;
  const ParchApp({super.key, required this.router, this.offline});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ParchApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: offline == null
          ? null
          : (context, child) => OfflineShell(api: offline!, child: child!),
    );
  }
}
