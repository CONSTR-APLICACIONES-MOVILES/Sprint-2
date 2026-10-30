import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/quick_status.dart';
import '../../domain/repositories/quick_status_repository.dart';

class PreferencesQuickStatusRepository implements QuickStatusRepository {
  final String project;
  const PreferencesQuickStatusRepository(this.project);
  String _key(String uid) =>
      'quick_status.v1.${Uri.encodeComponent(project)}.${Uri.encodeComponent(uid)}';
  @override
  Future<QuickStatus> load(String uid) async {
    final raw = (await SharedPreferences.getInstance()).getString(_key(uid));
    if (raw == null) return const QuickStatus();
    final data = jsonDecode(raw) as Map;
    return QuickStatus(
        freeUntil: data['freeUntil'] as String? ?? '',
        nextActivity: data['nextActivity'] as String? ?? '');
  }

  @override
  Future<QuickStatus> save(
      String uid, String freeUntil, String nextActivity) async {
    final result = (await load(uid)).update(freeUntil, nextActivity);
    final saved = await (await SharedPreferences.getInstance()).setString(
        _key(uid),
        jsonEncode({
          'freeUntil': result.freeUntil,
          'nextActivity': result.nextActivity
        }));
    if (!saved) throw StateError('Quick status could not be saved.');
    return result;
  }
}
