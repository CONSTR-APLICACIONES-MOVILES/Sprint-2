import 'package:flutter/material.dart';
import '../../../../shared/widgets/parch_app_bar.dart';

typedef MetricsSnapshot = Map<String, Map<String, dynamic>?>;

/// Reads the same server aggregates as the team's dashboard; never computes
/// alternative client-side rates or presents missing cohorts as zero percent.
class PlanningMetricsView extends StatefulWidget {
  final Future<MetricsSnapshot> Function() load;
  final Future<void> Function()? refresh;
  const PlanningMetricsView({super.key, required this.load, this.refresh});
  @override
  State<PlanningMetricsView> createState() => _MetricsState();
}

class _MetricsState extends State<PlanningMetricsView> {
  MetricsSnapshot? data;
  bool loading = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
      data = null;
    });
    try {
      if (refresh) await widget.refresh?.call();
      final result = await widget.load();
      if (mounted) setState(() => data = result);
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Unable to load current measurements. Check your connection and session, then retry.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String rate(dynamic value) => value == null ? 'Insufficient data' : '$value%';
  String stamp(dynamic value) {
    if (value == null) return 'Unknown';
    try {
      return (value.toDate() as DateTime).toLocal().toString();
    } catch (_) {
      return value.toString();
    }
  }

  Widget card(String id, String title,
      List<String> Function(Map<String, dynamic>) details) {
    final value = data?[id];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (value == null)
                  const Text('No published measurement yet.')
                else ...[
                  if (value['environment'] == 'test')
                    const Text('TEST DATA',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  for (final line in details(value))
                    Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(line)),
                  Text('Updated: ${stamp(value['updated_at'])}'),
                  Text(
                      'Window: ${stamp(value['window_start'])} to ${stamp(value['window_end'])}'),
                ],
              ],
            )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            const ParchAppBar(title: 'Planning measurements', showBack: true),
        body: RefreshIndicator(
            onRefresh: () => _load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                    'Server measurements from the same database as the team dashboard. Confirmation means activity status CONFIRMED, not agreement of every participant.'),
                if (loading) const LinearProgressIndicator(),
                if (error != null) Text(error!),
                TextButton(
                    onPressed: loading ? null : () => _load(),
                    child: const Text('Read latest aggregates')),
                if (widget.refresh != null)
                  OutlinedButton(
                      onPressed: loading ? null : () => _load(refresh: true),
                      child: const Text('Recalculate on server')),
                if (data != null) ...[
                  card(
                      'bq2_creation_reliability',
                      'BQ2 · Creation reliability',
                      (d) => [
                            'Failure or timeout: ${rate(d['failure_or_timeout_pct'])}',
                            'Attempts: ${d['attempts']} · Failure: ${d['failure']} · Timeout: ${d['timeout']} · Unresolved: ${d['unresolved']}',
                            'Coverage: ${rate(d['coverage_pct'])}. Instrumented Flutter network attempts only; validation and offline blocks are excluded.',
                          ]),
                  card(
                      'bq3_slot_acceptance',
                      'BQ3 · Unchanged acceptance',
                      (d) => [
                            rate(d['pct_unchanged_overall']),
                            '${d['accepted_recommendations_unchanged']} unchanged / ${d['sample_size']} presented candidates. Generated-only candidates are excluded.',
                          ]),
                  card(
                      'bq13_recommendation_confirmation',
                      'BQ13 · Recommendation confirmation',
                      (d) => [
                            rate(d['confirmation_rate']),
                            '${d['confirmed']} attributed confirmations / ${d['mature_opportunities']} mature opportunities. Pending: ${d['pending']} · Unknown: ${d['unknown']}',
                            'Observation: 24 hours after batch exposure. Only the selected unchanged candidate can receive credit.',
                            for (final r in d['by_segment'] as List? ?? [])
                              '${r['size']} · ${r['category']} · weekday ${r['weekday']} · ${r['bucket']}: ${rate(r['confirmation_rate'])} (n=${r['opportunities']})',
                          ]),
                  card(
                      'bq14_reminder_effectiveness',
                      'BQ14 · Reminder effectiveness',
                      (d) => [
                            'In-app alerts; not verified push delivery. Mature activities: ${d['mature_activities']} · Pending: ${d['pending']} · Unknown: ${d['unknown']}',
                            for (final r
                                in d['by_strategy_size'] as List? ?? [])
                              '${r['size']} · ${r['strategy']}: ${rate(r['confirmation_rate'])}, median ${r['median_minutes'] ?? 'unknown'} min, ${r['notifications_per_activity']} alerts/activity (n=${r['activities']})',
                            for (final r in d['decisions'] as List? ?? [])
                              '${r['size']}: ${r['sufficient'] == true ? r['strategy'] : 'Insufficient evidence or no joint improvement'}',
                            'Observational comparison over 24 hours from invitation. No causal winner is claimed from small samples.',
                          ]),
                ],
              ],
            )),
      );
}
