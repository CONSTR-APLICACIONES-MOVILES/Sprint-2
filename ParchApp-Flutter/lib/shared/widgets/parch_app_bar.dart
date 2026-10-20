import 'parch_visuals.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_routes.dart';
import '../../core/theme/app_colors.dart';

/// Shared global destinations. A missing unread count never becomes a badge.
class ParchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? initials;
  final int? unreadCount;
  final bool showBack;
  final bool isProfile;
  final bool isAlerts;
  final Future<void> Function()? onReturn;

  const ParchAppBar(
      {super.key,
      this.title = 'ParchApp',
      this.initials,
      this.unreadCount,
      this.showBack = false,
      this.isProfile = false,
      this.isAlerts = false,
      this.onReturn});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _open(BuildContext context, String route) async {
    if (GoRouterState.of(context).uri.path == route) return;
    await context.push(route);
    if (context.mounted) await onReturn?.call();
  }

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: showBack ? 0 : 16,
        leading: showBack
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
              )
            : null,
        title: title == 'ParchApp'
            ? const ParchBrand()
            : Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.outlineSoft)),
        actions: [
          IconButton(
              tooltip: 'Search',
              style: IconButton.styleFrom(
                  backgroundColor: AppColors.blueTint,
                  foregroundColor: AppColors.textPrimary),
              icon: const Icon(Icons.search_rounded, size: 21),
              onPressed: () => _open(context, AppRoutes.discover)),
          IconButton(
              tooltip: 'Notifications',
              onPressed:
                  isAlerts ? null : () => _open(context, AppRoutes.alerts),
              icon: Badge(
                  isLabelVisible: unreadCount != null && unreadCount! > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications_none_rounded))),
          IconButton(
              tooltip: 'Profile',
              onPressed:
                  isProfile ? null : () => _open(context, AppRoutes.profile),
              icon: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary,
                  child: initials == null || initials!.isEmpty
                      ? const Icon(Icons.person_outline,
                          color: Colors.white, size: 20)
                      : Text(initials!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)))),
          const SizedBox(width: 4),
        ],
      );
}
