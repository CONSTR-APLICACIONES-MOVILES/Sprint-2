import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_navigation_bar.dart';
import '../../domain/entities/profile_user.dart';
import '../view_models/profile_state.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/profile_cards.dart';
import '../widgets/profile_menu_tile.dart';
import '../widgets/profile_sheets.dart';

const _surface = Color(0xFFF8FAFE);

class ProfileView extends StatefulWidget {
  final ProfileViewModel viewModel;
  const ProfileView({super.key, required this.viewModel});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ProfileState>(
        valueListenable: widget.viewModel,
        builder: (context, state, _) => Scaffold(
          backgroundColor: _surface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            backgroundColor: _surface,
            surfaceTintColor: Colors.transparent,
            title: const Text('ParchApp',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
          ),
          body: SafeArea(top: false, bottom: false, child: _body(state)),
          bottomNavigationBar: const ParchNavigationBar(selectedIndex: 3),
        ),
      );

  Widget _body(ProfileState state) {
    final user = state.user;

    if (state.isLoading && user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_off_outlined,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(state.error ?? 'Profile unavailable',
                textAlign: TextAlign.center),
            TextButton(
                onPressed: widget.viewModel.load, child: const Text('Retry')),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (state.isUpdating) const LinearProgressIndicator(minHeight: 2),
          _header(user),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                ProfileIdentityCard(
                  user: user,
                  busy: state.isUpdating,
                  onChangeStatus: () => _changeStatus(user),
                ),
                const SizedBox(height: 18),
                ProfileAcademicCard(user: user),
                const SizedBox(height: 12),
                ProfileStatsRow(user: user),
                const ProfileSectionLabel('Availability & schedule'),
                ProfileMenuGroup(children: [
                  ProfileMenuTile(
                      icon: Icons.calendar_month_outlined,
                      title: 'Edit Availability',
                      subtitle: 'Fixed class hours & free time blocks',
                      onTap: () => context.push(AppRoutes.schedule)),
                ]),
                const ProfileSectionLabel('Community & groups'),
                ProfileMenuGroup(children: [
                  ProfileMenuTile(
                      icon: Icons.groups_2_outlined,
                      title: 'My Groups',
                      subtitle: '${user.activeGroups} groups',
                      onTap: () => context.push(AppRoutes.groups)),
                ]),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: state.isUpdating ? null : _logOut,
                  icon: const Icon(Icons.logout, size: 18),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  label: const Text('Log Out',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                const Text('ParchApp • Made for students',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(ProfileUser user) => Row(children: [
        if (context.canPop())
          IconButton(
              tooltip: 'Back',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back))
        else
          const SizedBox(width: 48),
        const Expanded(
          child: Column(children: [
            Text('My Profile',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text('University Account',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ]),
        ),
        IconButton(
            tooltip: 'Edit profile',
            onPressed: () => _edit(user),
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary)),
      ]);

  Future<void> _changeStatus(ProfileUser user) async {
    final status = await showProfileSheet<AvailabilityStatus>(context,
        child: AvailabilitySheet(current: user.status));
    if (!mounted || status == null || status == user.status) return;
    if (await widget.viewModel.changeStatus(status)) {
      _message('Availability updated');
    }
  }

  Future<void> _edit(ProfileUser user) async {
    final updated = await showProfileSheet<ProfileUser>(context,
        child: EditProfileSheet(user: user));
    if (!mounted || updated == null) return;
    if (await widget.viewModel.updateProfile(updated)) {
      _message('Profile updated');
    }
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final signedOut = await widget.viewModel.signOut();
    if (!mounted) return;
    if (signedOut) {
      context.go(AppRoutes.welcome);
    } else {
      _message(widget.viewModel.value.error ?? 'Unable to sign out.');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
