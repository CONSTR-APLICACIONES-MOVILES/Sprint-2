import 'package:flutter/material.dart';
import '../../core/domain/data_freshness.dart';
import '../../core/theme/app_colors.dart';

class DataFreshnessBanner extends StatelessWidget {
  final DataFreshness freshness;
  const DataFreshnessBanner({super.key, required this.freshness});
  @override
  Widget build(BuildContext context) {
    if (!freshness.offline) return const SizedBox.shrink();
    final date = freshness.cachedAt?.toUtc().subtract(const Duration(hours: 5));
    final time = date == null
        ? 'Save time unknown'
        : 'Saved ${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} · Bogotá';
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF5DB),
            borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  'Offline copy · $time${freshness.isStale(DateTime.now()) ? '\nMay be out of date. Reconnect to refresh.' : ''}',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12)))
        ]));
  }
}
