import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// One recoverable publication per account and project. Persist before sending.
class PublicationJournal {
  final SharedPreferences preferences;
  final String project, uid;
  const PublicationJournal(this.preferences,
      {required this.project, required this.uid});
  String get _key => 'publication.v1.$project.$uid';
  Map<String, dynamic>? read() {
    final text = preferences.getString(_key);
    return text == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  Future<void> write(Map<String, dynamic> publication) async {
    final prior = read();
    if (prior != null && jsonEncode(prior) != jsonEncode(publication)) {
      throw StateError(
          'Recover the previous publication before changing its details.');
    }
    if (!await preferences.setString(_key, jsonEncode(publication))) {
      throw StateError('Unable to persist this publication for retry.');
    }
  }

  Future<void> clear() async {
    await preferences.remove(_key);
  }
}
