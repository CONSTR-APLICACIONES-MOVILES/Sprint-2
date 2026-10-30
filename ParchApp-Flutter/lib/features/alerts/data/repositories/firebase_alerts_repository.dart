import '../../../../core/domain/data_freshness.dart';
import '../../../../core/data/mobile_api.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/app_alert.dart';
import '../../domain/repositories/alerts_repository.dart';

class FirebaseAlertsRepository
    implements AlertsRepository, CacheAwareRepository {
  @override
  DataFreshness freshness = const DataFreshness();
  final MobileApi _api;
  final AnalyticsService? analytics;
  final String? Function()? currentUserId;
  List<AppAlert> _items = [];
  String? _owner;
  FirebaseAlertsRepository(this._api, {this.analytics, this.currentUserId});

  String? _session() {
    final uid = currentUserId?.call();
    if (currentUserId != null) {
      if (_owner != uid) {
        _items = [];
        freshness = const DataFreshness();
      }
      _owner = uid;
      if (uid == null) throw StateError('Sign in to view alerts.');
    }
    return uid;
  }

  void _checkSession(String? uid) {
    if (currentUserId != null && currentUserId!() != uid) {
      _items = [];
      throw StateError('Session changed. Reload your alerts.');
    }
  }

  @override
  Future<List<AppAlert>> getAlerts() async {
    final uid = _session();
    final response = await _api.call('getAlerts', {});
    _checkSession(uid);
    freshness = DataFreshness.fromMap(response);
    final today = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    _items = [
      for (final raw in response['alerts'] as List)
        _alert(Map<String, dynamic>.from(raw as Map), today)
    ];
    _items.removeWhere((a) => a.kind == AlertKind.digest && a.isRead);
    return List.unmodifiable(_items);
  }

  AppAlert _alert(Map<String, dynamic> data, DateTime today) {
    final date = DateTime.parse(data['createdAt'] as String)
        .toUtc()
        .subtract(const Duration(hours: 5));
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    return AppAlert(
        id: data['id'] as String,
        kind: AlertKind.values.firstWhere((k) => k.name == data['kind'],
            orElse: () => AlertKind.invitation),
        authoritative: true,
        groupId: data['groupId'] as String?,
        requesterId: data['requesterId'] as String?,
        requesterName: data['requesterName'] as String?,
        requesterUsername: data['requesterUsername'] as String?,
        friendshipVersion: data['friendshipVersion'] as String?,
        period: isToday ? AlertPeriod.today : AlertPeriod.earlier,
        title: data['title'] as String,
        description: data['description'] as String,
        timeLabel: isToday
            ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
            : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        isRead: data['isRead'] == true,
        response: data['response'] == null
            ? null
            : AlertResponse.values.byName(data['response'] as String),
        studySessionId: data['studySessionId'] as String?,
        invitationSentAt: DateTime.parse(data['createdAt'] as String),
        groupSize: (data['groupSize'] as num?)?.toInt(),
        pendingSync: data['pendingSync'] == true);
  }

  @override
  Future<List<AppAlert>> markAllRead() async {
    final uid = _session();
    final ids = _items
        .where((item) => !item.isRead && item.kind == AlertKind.invitation)
        .map((item) => item.id)
        .toList();
    final events = _items
        .where((item) => !item.isRead && item.kind != AlertKind.invitation)
        .map((item) => item.id)
        .toList();
    if (ids.isNotEmpty) await _api.call('markAlertsRead', {'ids': ids});
    if (events.isNotEmpty) {
      await _api.call('markNotificationEventsRead',
          {'ids': events, if (uid != null) 'clientUserId': uid});
    }
    _checkSession(uid);
    _items = [
      for (final item in _items)
        if (item.kind != AlertKind.digest) item.copyWith(isRead: true)
    ];
    return List.unmodifiable(_items);
  }

  @override
  Future<List<AppAlert>> respond(String id, AlertResponse response) async {
    final uid = _session();
    final prior = _items.where((a) => a.id == id).firstOrNull;
    if (prior == null) throw StateError('Reload this invitation first.');
    if (prior.authoritative &&
        prior.kind == AlertKind.digest &&
        response == AlertResponse.dismissed) {
      await _api.call('markNotificationEventsRead', {
        'ids': [id],
        if (uid != null) 'clientUserId': uid
      });
      _checkSession(uid);
      _items.removeWhere((a) => a.id == id);
      return List.unmodifiable(_items);
    }
    if (prior.kind == AlertKind.friendRequest) {
      if (prior.isResolved ||
          prior.requesterId == null ||
          prior.friendshipVersion == null ||
          !{AlertResponse.accepted, AlertResponse.declined}
              .contains(response)) {
        throw StateError('Reload this friendship request first.');
      }
      await _api.call('changeFriendship', {
        'userId': prior.requesterId,
        'action': response == AlertResponse.accepted ? 'accept' : 'decline',
        'expectedVersion': prior.friendshipVersion,
        if (uid != null) 'clientUserId': uid,
      });
      _checkSession(uid);
      _items = [
        for (final item in _items)
          item.id == id ? item.copyWith(isRead: true, response: response) : item
      ];
      return List.unmodifiable(_items);
    }
    if (prior.kind != AlertKind.invitation) {
      throw StateError('Open the alert details to act on this event.');
    }
    final respondedAt = DateTime.now();
    final acknowledgement = await _api.call('respondToActivityInvitation', {
      'id': id,
      'response': response.name,
      'expectedResponse': prior.response?.name
    });
    _checkSession(uid);
    if (acknowledgement['pending'] != true &&
        analytics != null &&
        uid != null &&
        prior.response == null &&
        prior.invitationSentAt != null &&
        prior.groupSize != null &&
        [AlertResponse.accepted, AlertResponse.maybe, AlertResponse.declined]
            .contains(response)) {
      try {
        await analytics!.setUserId(uid);
        final elapsed =
            respondedAt.difference(prior.invitationSentAt!).inMilliseconds;
        await analytics!.track('rsvp_submitted', {
          'activity_id': id,
          'group_size': prior.groupSize!,
          'response_ms': elapsed < 0 ? 0 : elapsed,
          'response': switch (response) {
            AlertResponse.accepted => 'going',
            AlertResponse.maybe => 'maybe',
            _ => 'declined',
          },
        });
      } catch (_) {/* The invitation response is already saved. */}
    }
    _items = [
      for (final item in _items)
        item.id == id
            ? item.copyWith(
                isRead: true,
                response: response,
                pendingSync: acknowledgement['pending'] == true)
            : item
    ];
    return List.unmodifiable(_items);
  }
}
