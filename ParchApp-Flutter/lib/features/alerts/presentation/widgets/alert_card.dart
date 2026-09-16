import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_alert.dart';

const alertsGreen = Color(0xFF006E2F);
const alertsGreenTint = Color(0xFFD7F8D4);
const alertsBlueTint = Color(0xFFEFF4FF);
const alertsSurface = Color(0xFFF8F9FF);

class AlertCard extends StatelessWidget {
  final AppAlert alert;
  final bool busy;
  final ValueChanged<AlertResponse> onRespond;
  final VoidCallback onCreateActivity;
  final VoidCallback onProfile;
  final VoidCallback onDetails;

  const AlertCard(
      {super.key,
      required this.alert,
      required this.busy,
      required this.onRespond,
      required this.onCreateActivity,
      required this.onProfile,
      required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, tint) = switch (alert.kind) {
      AlertKind.overlap => (
          'SCHEDULE OVERLAP',
          Icons.auto_awesome,
          alertsGreen,
          alertsGreenTint
        ),
      AlertKind.friendRequest => (
          'FRIEND REQUEST',
          Icons.person_add_alt_1,
          AppColors.primary,
          alertsBlueTint
        ),
      AlertKind.reminder => (
          'URGENT REMINDER',
          Icons.alarm,
          const Color(0xFFBA1A1A),
          const Color(0xFFFFDAD6)
        ),
      AlertKind.invitation => (
          'INVITATION',
          Icons.mail_outline,
          AppColors.primary,
          alertsBlueTint
        ),
      AlertKind.timeChanged => (
          'TIME SHIFTED',
          Icons.swap_horiz,
          const Color(0xFF6746F5),
          const Color(0xFFF3E8FF)
        ),
      AlertKind.digest => (
          'WEEKLY DIGEST',
          Icons.forward_to_inbox,
          AppColors.primary,
          alertsBlueTint
        ),
      AlertKind.groupInvite => (
          'GROUP INVITE',
          Icons.hub_outlined,
          const Color(0xFF6746F5),
          const Color(0xFFF3E8FF)
        ),
    };
    final accented =
        alert.kind == AlertKind.overlap || alert.kind == AlertKind.reminder;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accented ? tint : const Color(0xFFE7EEF8)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F003D9B), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: accented
            ? BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 5)))
            : null,
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
              label: alert.kind == AlertKind.friendRequest
                  ? 'Carlos Mendoza'
                  : label,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: tint, borderRadius: BorderRadius.circular(16)),
                child: alert.kind == AlertKind.friendRequest
                    ? Center(
                        child: Text('CM',
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w800)))
                    : Icon(icon, color: color, size: 23),
              )),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(label,
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ),
                      Text(alert.timeLabel,
                          style: const TextStyle(
                              color: Color(0xFF74777F), fontSize: 11)),
                    ]),
                if (!alert.isRead) ...[
                  const SizedBox(height: 6),
                  Semantics(
                      label: 'Unread alert',
                      child: const Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.circle,
                              color: AppColors.primary, size: 6))),
                ],
                const SizedBox(height: 8),
                Text(alert.title,
                    style: const TextStyle(
                        color: Color(0xFF191C20),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3)),
                if (alert.kind == AlertKind.friendRequest) ...[
                  const SizedBox(height: 5),
                  const Text('● Active Now',
                      style: TextStyle(
                          color: alertsGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
                if (alert.kind == AlertKind.overlap) ...[
                  const SizedBox(height: 5),
                  const Text('100% Free Match',
                      style: TextStyle(
                          color: alertsGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 10),
                Text(alert.description,
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: Color(0xFF43474E))),
                if (alert.kind == AlertKind.friendRequest) ...[
                  const SizedBox(height: 8),
                  const Text(
                      '“Hey Alex, let’s sync calendars for the final workshop!”',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF74777F),
                          height: 1.4)),
                ],
                if (alert.kind == AlertKind.overlap) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: alertsBlueTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD8E2FF))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.timelapse,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text('Today • 1h 30m slot',
                                    style: TextStyle(
                                        color: Color(0xFF001A41),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)))
                          ]),
                          const SizedBox(height: 5),
                          const Text("Before Sarah's Lab at 19:00",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: alertsGreenTint,
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Text('Optimal',
                                  style: TextStyle(
                                      color: alertsGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                        ]),
                  ),
                ],
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFE7EEF8))),
                if (alert.kind == AlertKind.timeChanged) ...[
                  const Row(children: [
                    Icon(Icons.event_available, color: alertsGreen, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                        child: Text('Fits your schedule without conflict',
                            style: TextStyle(
                                color: alertsGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)))
                  ]),
                  const SizedBox(height: 8),
                ],
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _actions()),
              ])),
        ]),
      ),
    );
  }

  Widget _primary(String label, VoidCallback action, {IconData? icon}) =>
      FilledButton(
        onPressed: busy ? null : action,
        style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 17),
            const SizedBox(width: 6),
          ],
          Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _secondary(String label, AlertResponse response) => TextButton(
      onPressed: busy ? null : () => onRespond(response), child: Text(label));

  List<Widget> _actions() => switch (alert.kind) {
        AlertKind.overlap => [
            _primary('1-Tap Create Activity', onCreateActivity,
                icon: Icons.add_circle),
            _secondary('Dismiss', AlertResponse.dismissed)
          ],
        AlertKind.friendRequest => [
            _primary('Accept', () => onRespond(AlertResponse.accepted),
                icon: Icons.person_add_alt_1),
            _secondary('Decline', AlertResponse.declined),
            IconButton(
                tooltip: 'View Carlos profile',
                onPressed: busy ? null : onProfile,
                icon:
                    const Icon(Icons.account_circle, color: AppColors.primary)),
          ],
        AlertKind.reminder => [
            _primary("I'm on my way", () => onRespond(AlertResponse.onMyWay),
                icon: Icons.directions_walk),
            TextButton(
                onPressed: onDetails,
                child: Text(
                    alert.studySessionId == null ? 'View Map' : 'View session'))
          ],
        AlertKind.invitation => [
            _primary('Accept', () => onRespond(AlertResponse.accepted),
                icon: Icons.check),
            _secondary('Maybe', AlertResponse.maybe),
            _secondary('Decline', AlertResponse.declined)
          ],
        AlertKind.timeChanged => [
            _primary('Acknowledge', () => onRespond(AlertResponse.acknowledged))
          ],
        AlertKind.digest => [
            _primary('Review Now', onDetails, icon: Icons.checklist),
            _secondary('Dismiss', AlertResponse.dismissed)
          ],
        AlertKind.groupInvite => [
            _primary('Join Group', () => onRespond(AlertResponse.joined)),
            _secondary('Decline', AlertResponse.declined)
          ],
      };
}
