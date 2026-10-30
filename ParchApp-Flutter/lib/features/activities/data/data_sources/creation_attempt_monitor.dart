import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

typedef MetricSender = Future<void> Function(Map<String, dynamic> event);

/// Durable client observations. A telemetry failure never changes publication.
/// Each phase has its own immutable key, so a late ACK cannot delete a result.
class CreationAttemptMonitor {
  final SharedPreferences preferences;
  final String project, uid;
  final MetricSender send;
  final bool Function() canSend;
  final Duration deadline;
  final DateTime Function() clock;
  Future<void>? _flushing;
  int storageFailures = 0;

  CreationAttemptMonitor(this.preferences,
      {required this.project,
      required this.uid,
      required this.send,
      required this.canSend,
      this.deadline = const Duration(seconds: 8),
      DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  String get prefix =>
      'creation-metrics.v1.${base64Url.encode(utf8.encode(project))}.${base64Url.encode(utf8.encode(uid))}.';

  Future<void> _store(Map<String, dynamic> event) async {
    try {
      final key = '$prefix${event['attemptId']}.${event['phase']}';
      if (!await preferences.setString(key, jsonEncode(event))) {
        storageFailures++;
      }
    } catch (_) {
      storageFailures++;
    }
  }

  /// Safe to call on reconnect or restored session, even with nothing pending.
  Future<void> flush() =>
      _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<void> _flush() async {
    try {
      while (canSend()) {
        final keys = preferences
            .getKeys()
            .where((k) => k.startsWith(prefix))
            .toList()
          ..sort();
        if (keys.isEmpty) return;
        for (final key in keys) {
          if (!canSend()) return;
          final raw = preferences.getString(key);
          if (raw == null) continue;
          final event = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          await send({...event, 'clientUserId': uid})
              .timeout(const Duration(seconds: 4));
          if (preferences.getString(key) == raw) await preferences.remove(key);
        }
      }
    } catch (_) {
      // Persisted observations retry next session/reconnect/publication.
    }
  }

  Future<T> observe<T>(String requestId, Future<T> Function() publish) async {
    final random = Random.secure();
    final attemptId =
        '${clock().microsecondsSinceEpoch}-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    final base = <String, dynamic>{
      'attemptId': attemptId,
      'requestId': requestId,
      'startedAt': clock().toUtc().toIso8601String(),
    };
    await _store({...base, 'phase': 'start'});
    unawaited(flush());
    final elapsed = Stopwatch()..start();
    var timedOut = false;
    String code(Object error) {
      // Firebase exceptions have code; keep the persisted schema bounded.
      try {
        final value = (error as dynamic).code as String;
        if (RegExp(r'^[a-z0-9-]{1,64}$').hasMatch(value)) return value;
      } catch (_) {}
      return 'unknown';
    }

    Future<void> record(String phase, String outcome, [Object? error]) async {
      await _store({
        ...base,
        'phase': phase,
        'outcome': outcome,
        'durationMs': elapsed.elapsedMilliseconds.clamp(0, 604800000),
        if (error != null) 'errorCode': code(error),
      });
      unawaited(flush());
    }

    final network = Future<T>.sync(publish);
    // Timeout does not cancel the server operation. Preserve the late outcome
    // separately, even if the UI already returned to the recoverable editor.
    unawaited(network.then<void>((_) async {
      if (timedOut) await record('reconcile', 'success');
    }, onError: (Object error, StackTrace stack) async {
      if (timedOut) await record('reconcile', 'failure', error);
    }));
    try {
      final receipt = await network.timeout(deadline, onTimeout: () {
        timedOut = true;
        throw TimeoutException(
            'Publication acknowledgement timed out.', deadline);
      });
      await record('result', 'success');
      return receipt;
    } on TimeoutException {
      timedOut = true;
      await record('result', 'timeout');
      rethrow;
    } catch (error) {
      final timeout = code(error) == 'deadline-exceeded';
      await record('result', timeout ? 'timeout' : 'failure', error);
      rethrow;
    }
  }
}
