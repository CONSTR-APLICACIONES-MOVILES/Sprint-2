import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_routes.dart';
import '../../core/theme/app_colors.dart';

class ParchNavigationBar extends StatelessWidget {
  final int selectedIndex;
  const ParchNavigationBar({super.key, this.selectedIndex = 0});
  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.availabilityLight,
        onDestinationSelected: (index) => context.go([
          AppRoutes.home,
          AppRoutes.groups,
          AppRoutes.schedule,
          AppRoutes.profile
        ][index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined), label: 'Groups'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      );
}
