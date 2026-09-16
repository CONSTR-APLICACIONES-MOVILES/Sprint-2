import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/parch_navigation_bar.dart';
import '../../../../core/theme/app_colors.dart';

const _cobalt = AppColors.primary;
const _emerald = AppColors.success;
const _background = Color(0xFFF8FAFE);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _blueTint = Color(0xFFEEF4FF);
const _greenTint = Color(0xFFECFDF5);

/// Presentation-only dashboard preview. Replace the sample values and action
/// placeholders with injected HomeViewModel state and commands when available.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const _inviteLink = 'parchapp.me/u/alex-k26';
  static const _studyTitle = 'Study Session: Linear Algebra & Calculus';
  static const _soccerTitle = '5-a-side Soccer & Social';

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      textTheme: Theme.of(context).textTheme,
      scaffoldBackgroundColor: _background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _cobalt,
        brightness: Brightness.light,
      ).copyWith(
        primary: _cobalt,
        onPrimary: Colors.white,
        secondary: _emerald,
        onSecondary: _ink,
        surface: Colors.white,
        onSurface: _ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _cobalt,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _cobalt,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: _buildAppBar(context),
          body: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGreeting(context),
                      const SizedBox(height: 20),
                      _buildInviteCard(context),
                      const SizedBox(height: 16),
                      _buildQuickStatus(context),
                      const SizedBox(height: 24),
                      _sectionHeading(
                        "Today's Plans",
                        count: '2',
                        trailing: TextButton.icon(
                          onPressed: () => _onCalendarTapped(context),
                          icon: const Icon(Icons.calendar_month_outlined,
                              size: 16),
                          label: const Text('View calendar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        context,
                        title: _studyTitle,
                        time: '4:00 PM – 6:00 PM',
                        location: 'Central Library • Room 302',
                        confirmed: true,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        context,
                        title: _soccerTitle,
                        time: 'Friday, 7:30 PM',
                        location: 'Campus Sports Center',
                        confirmed: false,
                      ),
                      const SizedBox(height: 24),
                      _sectionHeading(
                        'Your Active Groups',
                        trailing: TextButton(
                          onPressed: () => _onAllGroupsTapped(context),
                          child: const Text('View all (5)'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGroups(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _onNewActivity(context),
            backgroundColor: _cobalt,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('New Activity'),
          ),
          bottomNavigationBar: const ParchNavigationBar(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: _background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/images/parchapp_logo.png',
            width: 32,
            height: 32,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.people_alt_rounded,
              color: _cobalt,
              size: 30,
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'ParchApp',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: _cobalt, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: () => _onSearch(context),
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => _onNotifications(context),
          icon: const Badge(
            smallSize: 7,
            backgroundColor: Color(0xFFF43F5E),
            child: Icon(Icons.notifications_none_rounded),
          ),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: () => _onProfile(context),
          icon: const CircleAvatar(
            radius: 17,
            backgroundColor: _cobalt,
            child: Text('AK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, Alex! 👋',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  )),
              SizedBox(height: 6),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'You have '),
                  TextSpan(
                      text: '2 active plans',
                      style: TextStyle(
                        color: _cobalt,
                        fontWeight: FontWeight.w700,
                      )),
                  TextSpan(text: ' today'),
                ]),
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ActionChip(
          avatar: const Icon(Icons.circle, size: 9, color: _emerald),
          label: const Text('FREE',
              style: TextStyle(
                color: Color(0xFF047857),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              )),
          backgroundColor: _greenTint,
          side: const BorderSide(color: Color(0xFFA7F3D0)),
          onPressed: () => _onQuickStatusTapped(context),
        ),
      ],
    );
  }

  Widget _buildInviteCard(BuildContext context) {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconTile(Icons.share_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invite Friends to Sync',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 5),
                    Text(
                      'Share your link so classmates can connect and sync calendars in seconds',
                      style:
                          TextStyle(color: _muted, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: _background,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.link, size: 18, color: _muted),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text(
                _inviteLink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: _muted),
              )),
              IconButton.filled(
                tooltip: 'Copy link',
                onPressed: () => _onCopyInvite(context),
                icon: const Icon(Icons.copy_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'Share invite link',
                onPressed: () => _onShare(context),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatus(BuildContext context) {
    return _surface(
      color: _cobalt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                _iconTile(Icons.bolt_rounded,
                    foreground: Colors.white,
                    background: const Color(0x33FFFFFF)),
                const SizedBox(width: 10),
                const Flexible(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('QUICK STATUS',
                        style: TextStyle(
                          color: Color(0xFFBFDBFE),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        )),
                    SizedBox(height: 4),
                    Text('Available Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                )),
              ]),
              _pill('Live Sync',
                  foreground: Colors.white,
                  background: const Color(0x33FFFFFF),
                  icon: Icons.circle,
                  iconColor: _emerald),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final stacked = constraints.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final tiles = [
              _statusTile(context, 'FREE UNTIL', '4:00 PM'),
              _statusTile(context, 'NEXT ACTIVITY', 'Library Study'),
            ];
            if (stacked) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tiles[0],
                    const SizedBox(height: 10),
                    tiles[1],
                  ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: 10),
              Expanded(child: tiles[1]),
            ]);
          }),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: _cobalt),
            onPressed: () => _onCompareAvailability(context),
            child: const Row(children: [
              Icon(Icons.bolt_rounded, size: 20),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Compare Availability with Group',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800))),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(BuildContext context, String label, String value) {
    return Material(
      color: const Color(0x1FFFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onQuickStatusTapped(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ))),
              const Icon(Icons.edit_outlined,
                  color: Color(0xFFBFDBFE), size: 14),
            ]),
            const SizedBox(height: 7),
            Text(value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                )),
          ]),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String time,
    required String location,
    required bool confirmed,
  }) {
    void openDetails() => _onPlanTapped(context,
        title: title, time: time, location: location, confirmed: confirmed);

    return _surface(
      onTap: openDetails,
      accented: !confirmed,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Align(
            alignment: Alignment.centerLeft,
            child: _pill(
              confirmed ? 'Confirmed • 4/4 ready' : 'Voting pending • 3/6',
              foreground: confirmed ? const Color(0xFF047857) : _cobalt,
              background: confirmed ? _greenTint : _blueTint,
              icon: confirmed ? Icons.check_rounded : Icons.schedule_rounded,
            ),
          )),
          IconButton(
            tooltip: 'Options for $title',
            onPressed: () => _onPlanOptions(context, title),
            icon: const Icon(Icons.more_vert, color: _muted),
          ),
        ]),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 14),
        _info(Icons.schedule_outlined, time),
        const SizedBox(height: 8),
        _info(Icons.location_on_outlined, location),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: confirmed ? 1 : 0.5,
            minHeight: 6,
            color: confirmed ? _emerald : _cobalt,
            backgroundColor: const Color(0xFFF1F5F9),
            semanticsLabel: confirmed
                ? 'Four of four participants ready'
                : 'Three of six participants have voted',
          ),
        ),
        const SizedBox(height: 14),
        if (confirmed)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildAvatars(),
              TextButton(onPressed: openDetails, child: const Text('Details')),
            ],
          )
        else
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text('Joining?',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: _emerald, foregroundColor: _ink),
                  onPressed: () => _onRsvp(context, 'Going'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Going'),
                ),
                OutlinedButton(
                  onPressed: () => _onRsvp(context, 'Maybe'),
                  child: const Text('Maybe'),
                ),
              ]),
            ],
          ),
      ]),
    );
  }

  Widget _buildAvatars() {
    const initials = ['MK', 'SR', 'JD', '+1'];
    const colors = [Color(0xFF60A5FA), Color(0xFF6366F1), _emerald, _cobalt];
    return Semantics(
      label: 'Four participants',
      child: ExcludeSemantics(
          child: SizedBox(
        width: 108,
        height: 34,
        child: Stack(children: [
          for (var index = 0; index < initials.length; index++)
            Positioned(
              left: index * 24,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors[index],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(initials[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    )),
              ),
            ),
        ]),
      )),
    );
  }

  Widget _buildGroups(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 320 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final width =
          stacked ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
            width: width,
            child: _groupCard(context,
                title: 'Engineering 2026',
                subtitle: '28 members',
                icon: Icons.school_outlined,
                action: 'Open chat',
                engineering: true)),
        SizedBox(
            width: width,
            child: _groupCard(context,
                title: 'Roomies Main St',
                subtitle: '4 members • 1 plan',
                icon: Icons.home_outlined,
                action: 'View status',
                engineering: false)),
      ]);
    });
  }

  Widget _groupCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String action,
    required bool engineering,
  }) {
    return _surface(
      onTap: () => _onGroupTapped(context, title, subtitle),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _iconTile(icon,
                  foreground: engineering ? _cobalt : const Color(0xFF9333EA),
                  background:
                      engineering ? _blueTint : const Color(0xFFF3E8FF)),
              if (engineering)
                const Text('10m ago',
                    style: TextStyle(color: _muted, fontSize: 10)),
            ]),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _onGroupTapped(context, title, subtitle),
          child: Text('$action →'),
        ),
      ]),
    );
  }

  Widget _sectionHeading(String title,
      {required Widget trailing, String? count}) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: _ink, fontSize: 17, fontWeight: FontWeight.w800)),
              if (count != null)
                _pill(count, foreground: _cobalt, background: _blueTint),
            ]),
        trailing,
      ],
    );
  }

  Widget _surface(
      {required Widget child,
      Color color = Colors.white,
      VoidCallback? onTap,
      bool accented = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color == _cobalt
                ? const Color(0x240047BA)
                : const Color(0x080F172A),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
              color: color == _cobalt ? _cobalt : const Color(0xFFF1F5F9)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: accented
                ? const BoxDecoration(
                    border: Border(left: BorderSide(color: _cobalt, width: 4)),
                  )
                : null,
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon,
      {Color foreground = _cobalt, Color background = _blueTint}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(13)),
      child: Icon(icon, color: foreground, size: 21),
    );
  }

  Widget _pill(String label,
      {required Color foreground,
      required Color background,
      IconData? icon,
      Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(30)),
      child: Text.rich(
        TextSpan(children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(icon, size: 12, color: iconColor ?? foreground),
              ),
            ),
          TextSpan(text: label),
        ]),
        style: TextStyle(
            color: foreground, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _cobalt, size: 17),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style:
                  const TextStyle(color: _muted, fontSize: 12, height: 1.5))),
    ]);
  }

  Future<void> _showSheet(BuildContext context, String title,
      List<Widget> Function(BuildContext sheetContext) content) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
          maxWidth: 600, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 24 + MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ))),
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 16),
              ...content(sheetContext),
            ],
          ),
        ),
      ),
    );
  }

  void _onQuickStatusTapped(BuildContext context) {
    var freeUntil = '4:00 PM';
    var nextActivity = 'Library Study';
    _showSheet(
        context,
        'Update Availability & Status',
        (sheetContext) => [
              StatefulBuilder(
                  builder: (context, setSheetState) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Free Until',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final time in [
                              '3:00 PM',
                              '4:00 PM',
                              '5:00 PM',
                              '6:00 PM'
                            ])
                              ChoiceChip(
                                  label: Text(time),
                                  selected: freeUntil == time,
                                  onSelected: (_) =>
                                      setSheetState(() => freeUntil = time)),
                          ]),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: ValueKey('time-$freeUntil'),
                            initialValue: freeUntil,
                            decoration: const InputDecoration(
                                labelText: 'Custom time',
                                hintText: 'e.g. 4:30 PM'),
                            onChanged: (value) => freeUntil = value,
                          ),
                          const SizedBox(height: 20),
                          const Text('Next Activity',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final activity in [
                              'Library Study',
                              'Linear Algebra',
                              'Gym Workout',
                              'Group Project'
                            ])
                              ChoiceChip(
                                  label: Text(activity),
                                  selected: nextActivity == activity,
                                  onSelected: (_) => setSheetState(
                                      () => nextActivity = activity)),
                          ]),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: ValueKey('activity-$nextActivity'),
                            initialValue: nextActivity,
                            decoration: const InputDecoration(
                                labelText: 'Activity name'),
                            onChanged: (value) => nextActivity = value,
                          ),
                        ],
                      )),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Save Changes'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _onUpdateStatus(context, freeUntil, nextActivity);
                },
              ),
            ]);
  }

  void _onPlanTapped(BuildContext context,
      {required String title,
      required String time,
      required String location,
      required bool confirmed}) {
    if (title == _studyTitle) {
      context.push(AppRoutes.studySession('linear-algebra'));
      return;
    }
    _showSheet(
        context,
        'Plan Details',
        (sheetContext) => [
              _pill(
                  confirmed ? 'Confirmed • 4/4 ready' : 'Voting pending • 3/6',
                  foreground: confirmed ? const Color(0xFF047857) : _cobalt,
                  background: confirmed ? _greenTint : _blueTint),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _info(Icons.schedule, time),
              const SizedBox(height: 12),
              _info(Icons.location_on_outlined, location),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  // TODO: Forward the calendar action to HomeViewModel.
                  _showMessage(context, 'Calendar sync is coming soon.');
                },
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Add to Calendar'),
              ),
            ]);
  }

  void _onCalendarTapped(BuildContext context) {
    _showSheet(
        context,
        'Calendar & Sync',
        (sheetContext) => [
              _info(Icons.schedule, '4:00 PM – 6:00 PM'),
              const SizedBox(height: 8),
              const Text(_studyTitle),
              const SizedBox(height: 8),
              _info(Icons.location_on_outlined, 'Central Library • Room 302'),
              const SizedBox(height: 24),
              _pill('Free Availability Block',
                  foreground: const Color(0xFF047857), background: _greenTint),
              const SizedBox(height: 8),
              const Text('6:00 PM – 7:30 PM • 1h 30m free'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/schedule');
                },
                child: const Text('Open schedule'),
              ),
            ]);
  }

  Future<void> _onCompareAvailability(BuildContext context) async {
    var createPlan = false;
    await _showSheet(
        context,
        'Group Availability',
        (sheetContext) => [
              const Text('Best Mutual Match',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _pill('4/4 Free',
                  foreground: const Color(0xFF047857),
                  background: _greenTint,
                  icon: Icons.check),
              const SizedBox(height: 16),
              const Text('6:00 PM – 7:30 PM',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Everyone is out of classes and free before dinner.',
                  style: TextStyle(color: _muted)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  createPlan = true;
                  Navigator.of(sheetContext).pop();
                },
                icon: const Icon(Icons.add),
                label: const Text('Schedule Plan in Free Slot'),
              ),
            ]);
    if (createPlan && context.mounted) _onNewActivity(context);
  }

  void _onGroupTapped(BuildContext context, String title, String subtitle) {
    _showSheet(
        context,
        title,
        (sheetContext) => [
              Text(subtitle, style: const TextStyle(color: _muted)),
              const SizedBox(height: 20),
              const Text('Recent Shared Status',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(title == 'Engineering 2026'
                  ? 'Linear Algebra midterm study planned for Central Library Room 302 at 4:00 PM.'
                  : '5-a-side Soccer & Social at Campus Sports Center.'),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  // TODO: Forward the availability request to HomeViewModel.
                  _showMessage(
                      context, 'Availability requests are coming soon.');
                },
                icon: const Icon(Icons.bolt),
                label: const Text('Ping Availability'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  // TODO: Navigate to the group's chat when its route exists.
                  _showMessage(context, 'Group chat is coming soon.');
                },
                child: const Text('Open Chat'),
              ),
            ]);
  }

  void _onAllGroupsTapped(BuildContext context) {
    _showSheet(
        context,
        'All Active Groups (5)',
        (sheetContext) => [
              const ListTile(
                  leading: Icon(Icons.school_outlined, color: _cobalt),
                  title: Text('Engineering 2026'),
                  subtitle: Text('28 members • 10m ago')),
              const ListTile(
                  leading: Icon(Icons.home_outlined, color: Color(0xFF9333EA)),
                  title: Text('Roomies Main St'),
                  subtitle: Text('4 members • 1 plan')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/groups');
                },
                child: const Text('Open groups'),
              ),
            ]);
  }

  void _onNewActivity(BuildContext context) {
    var title = 'Midterm Review & Coffee';
    var time = 'Tomorrow, 3:00 PM';
    var location = 'Campus Cafe';
    _showSheet(
        context,
        'Create New Activity',
        (sheetContext) => [
              TextFormField(
                  initialValue: title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Activity name'),
                  onChanged: (value) => title = value),
              const SizedBox(height: 16),
              TextFormField(
                  initialValue: time,
                  decoration: const InputDecoration(labelText: 'Time'),
                  onChanged: (value) => time = value),
              const SizedBox(height: 16),
              TextFormField(
                  initialValue: location,
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (value) => location = value),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _onPublishActivity(context, title, time, location);
                },
                child: const Text('Publish & Invite'),
              ),
            ]);
  }

  void _onPlanOptions(BuildContext context, String title) {
    _showSheet(
        context,
        'Activity Options',
        (sheetContext) => [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final option in [
                (Icons.share_outlined, 'Share Plan with Friends'),
                (Icons.notifications_outlined, 'Set Alert Reminder'),
                (Icons.close_rounded, 'Leave / Cancel RSVP'),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(option.$1, color: _cobalt),
                  title: Text(option.$2),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    // TODO: Forward the selected action to HomeViewModel.
                    _showMessage(context, '${option.$2} is coming soon.');
                  },
                ),
            ]);
  }

  void _onShare(BuildContext context) {
    _showSheet(
        context,
        'Share Sync Link',
        (sheetContext) => [
              const SelectableText('https://$_inviteLink'),
              const SizedBox(height: 16),
              for (final option in [
                (Icons.chat_outlined, 'WhatsApp'),
                (Icons.sms_outlined, 'Messages'),
                (Icons.copy_outlined, 'Copy Link'),
                (Icons.qr_code_rounded, 'QR Code'),
              ])
                ListTile(
                  leading: Icon(option.$1, color: _cobalt),
                  title: Text(option.$2),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    // TODO: Forward sharing to an injected presentation action.
                    _showMessage(
                        context, '${option.$2} sharing is coming soon.');
                  },
                ),
            ]);
  }

  void _onSearch(BuildContext context) {
    _showSheet(
        context,
        'Search',
        (sheetContext) => [
              TextField(
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                    hintText: 'Search plans, classmates, groups...',
                    prefixIcon: Icon(Icons.search)),
                onSubmitted: (query) {
                  Navigator.of(sheetContext).pop();
                  // TODO: Forward query to HomeViewModel.
                  _showMessage(context, 'Search is coming soon.');
                },
              ),
            ]);
  }

  void _onNotifications(BuildContext context) {
    context.go(AppRoutes.alerts);
  }

  void _onProfile(BuildContext context) {
    _showSheet(
        context,
        'Student Profile',
        (_) => [
              const Center(
                  child: CircleAvatar(
                radius: 32,
                backgroundColor: _cobalt,
                child: Text('AK',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              )),
              const SizedBox(height: 16),
              const Text('Alex Kuprev',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Computer Science • Class of 2026',
                  textAlign: TextAlign.center, style: TextStyle(color: _muted)),
            ]);
  }

  void _onUpdateStatus(
      BuildContext context, String freeUntil, String nextActivity) {
    // TODO: HomeViewModel.updateStatus(freeUntil, nextActivity).
    _showMessage(context, 'Status updates are coming soon.');
  }

  void _onPublishActivity(
      BuildContext context, String title, String time, String location) {
    // TODO: Forward the draft to HomeViewModel; validate in the domain layer.
    _showMessage(context, 'Activity publishing is coming soon.');
  }

  void _onRsvp(BuildContext context, String response) {
    // TODO: HomeViewModel.respondToPlan(response).
    _showMessage(context, 'RSVP updates are coming soon.');
  }

  void _onCopyInvite(BuildContext context) {
    // TODO: Forward clipboard interaction to an injected presentation action.
    _showMessage(context, 'Invite link copying is coming soon.');
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
