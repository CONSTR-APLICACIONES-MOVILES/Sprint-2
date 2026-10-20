import 'package:cloud_functions/cloud_functions.dart';
import '../../../activities/domain/entities/study_session.dart'
    show SessionFailure;
import '../../../../core/data/mobile_api.dart';
import '../../../activities/domain/entities/planning_context.dart';
import '../../domain/entities/schedule_block.dart';
import '../../domain/entities/schedule_friend.dart';
import '../../domain/repositories/schedule_repository.dart';

class FirebaseScheduleRepository
    implements ScheduleRepository, PlanningSlotValidator {
  final MobileApi _api;
  final String? Function() _userId;
  final String? groupId;
  FirebaseScheduleRepository(this._api, this._userId, {this.groupId});
  FirebaseScheduleRepository forGroup(String id) =>
      FirebaseScheduleRepository(_api, _userId, groupId: id);

  @override
  Future<PlanningContext> validatePlanningSlot(PlanningContext context) async {
    try {
      return PlanningContext.fromMap(
          await _api.call('validatePlanningSlot', context.toMap()));
    } on FirebaseFunctionsException catch (error) {
      throw SessionFailure([
        'failed-precondition',
        'permission-denied',
        'invalid-argument'
      ].contains(error.code)
          ? error.message ?? 'Compare this slot again.'
          : 'Unable to validate this slot. Check your connection and compare again.');
    } on StateError {
      throw const SessionFailure(
          'Validating a slot requires a connection. Reconnect and compare again.');
    }
  }

  @override
  Future<List<ScheduleFriend>> getFriends() async {
    final response = await _api
        .call('getScheduleFriends', {if (groupId != null) 'groupId': groupId});
    return [
      for (final raw in response['friends'] as List)
        ScheduleFriend(
            id: raw['id'] as String,
            name: raw['name'] as String,
            fullName: raw['name'] as String,
            initials: raw['initials'] as String)
    ];
  }

  String _date(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<List<ScheduleBlock>> _load(
      DateTime day, List<String> friends, bool personal) async {
    final uid = _userId();
    if (uid == null) throw StateError('Sign in to view schedules.');
    final response = await _api
        .call('getScheduleDay', {'date': _date(day), 'friendIds': friends});
    final schedules = (response['schedules'] as List)
        .where((s) => personal ? s['ownerId'] == uid : s['ownerId'] != uid)
        .toList();
    if (schedules.any((s) => s['known'] != true)) {
      throw StateError('Availability is not synced for this day.');
    }
    return [
      for (final schedule in schedules)
        for (final block in schedule['busy'] as List)
          ScheduleBlock(
            id: '${schedule['ownerId']}-${_date(day)}-${block['start']}-${block['end']}',
            ownerId: schedule['ownerId'] as String,
            start: DateTime(day.year, day.month, day.day)
                .add(Duration(minutes: (block['start'] as num).toInt())),
            end: DateTime(day.year, day.month, day.day)
                .add(Duration(minutes: (block['end'] as num).toInt())),
            type: personal
                ? ScheduleBlockType.personalEvent
                : ScheduleBlockType.friendBusy,
            title: personal ? 'Busy' : null,
          )
    ];
  }

  @override
  Future<List<ScheduleBlock>> getMySchedule({required DateTime day}) =>
      _load(day, [], true);
  @override
  Future<List<ScheduleBlock>> getFriendsBusyBlocks(
          {required DateTime day, required List<String> friendIds}) =>
      friendIds.isEmpty ? Future.value([]) : _load(day, friendIds, false);

  @override
  Future<void> replaceImportedCalendarBlocks(List<ScheduleBlock> blocks) async {
    final today = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    await _api.call('importCalendarAvailability', {
      'startDate': _date(today),
      'days': 56,
      'intervals': [
        for (final block in blocks)
          {
            'start': block.start.toUtc().toIso8601String(),
            'end': block.end.toUtc().toIso8601String(),
          }
      ],
    });
  }
}
