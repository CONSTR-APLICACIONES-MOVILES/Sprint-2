import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../../../../shared/widgets/parch_visuals.dart';

class CoordinationInsightsView extends StatefulWidget {
  final Future<Map<String, dynamic>?> Function() loadInsight;
  const CoordinationInsightsView({super.key, required this.loadInsight});
  @override
  State<CoordinationInsightsView> createState() =>
      _CoordinationInsightsViewState();
}

class _CoordinationInsightsViewState extends State<CoordinationInsightsView> {
  late Future<Map<String, dynamic>?> _result = widget.loadInsight();
  void _refresh() => setState(() {
        _result = widget.loadInsight();
      });
  String _percent(dynamic value) => value == null
      ? 'No data'
      : '${((value as num) * 100).toStringAsFixed(1)}%';
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const ParchAppBar(showBack: true),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Planning insights',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 25)),
                            const SizedBox(height: 8),
                            const Text(
                                'Does comparing availability help groups confirm their plans?'),
                            const SizedBox(height: 20),
                            FutureBuilder<Map<String, dynamic>?>(
                                future: _result,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done) {
                                    return const LinearProgressIndicator();
                                  }
                                  if (snapshot.hasError) {
                                    return ParchSurface(
                                        child: Column(children: [
                                      const Text(
                                          'Unable to load insights. Your activities are unchanged.'),
                                      TextButton(
                                          onPressed: _refresh,
                                          child: const Text('Retry'))
                                    ]));
                                  }
                                  final data = snapshot.data;
                                  if (data == null) {
                                    return const ParchSurface(
                                        child: Text(
                                            'No published measurement yet. Cohorts need seven complete days of follow-up.'));
                                  }
                                  final compared = Map<String, dynamic>.from(
                                          data['compared'] as Map),
                                      direct = Map<String, dynamic>.from(
                                          data['direct'] as Map);
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (data['environment'] == 'test')
                                          const Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 12),
                                              child: ParchPill(
                                                  'Local test data',
                                                  color: AppColors.warning)),
                                        ParchSurface(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              const Text(
                                                  'Comparison used before creation',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 8),
                                              Text(
                                                  _percent(
                                                      data['comparisonUsage']),
                                                  style: const TextStyle(
                                                      fontSize: 30,
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                              Text(
                                                  '${data['known']} measured activities · ${_percent(data['coverage'])} coverage'),
                                              Text(
                                                  '${data['unknown']} activities have unknown attribution.')
                                            ])),
                                        const SizedBox(height: 14),
                                        for (final entry in [
                                          ('With comparison', compared),
                                          ('Without comparison', direct)
                                        ])
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 14),
                                              child: ParchSurface(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Text(entry.$1,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .textPrimary)),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        _percent(entry.$2[
                                                            'confirmationRate']),
                                                        style: const TextStyle(
                                                            fontSize: 26,
                                                            color: AppColors
                                                                .success,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800)),
                                                    Text(
                                                        '${entry.$2['confirmed']} of ${entry.$2['activities']} confirmed within 7 days')
                                                  ]))),
                                        Text(
                                            data['differencePp'] == null
                                                ? 'Difference: No data'
                                                : 'Difference: ${(data['differencePp'] as num).toStringAsFixed(1)} percentage points',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 12),
                                        Text(
                                            'Creation window: ${data['windowStart'].toString().substring(0, 10)} to ${data['windowEnd'].toString().substring(0, 10)} (exclusive) · Bogotá'),
                                        Text('Updated: ${data['updatedAt']}'),
                                        const SizedBox(height: 10),
                                        const Text(
                                            'Association does not establish causation. Category and group size can influence the result.',
                                            style: TextStyle(fontSize: 12)),
                                      ]);
                                }),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh')),
                          ]))))));
}
