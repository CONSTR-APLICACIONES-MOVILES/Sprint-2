import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/schedule_block.dart';
import '../../domain/entities/schedule_friend.dart';
import '../../domain/repositories/schedule_repository.dart';

class FirebaseScheduleRepository
    implements ScheduleRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const FirebaseScheduleRepository({
    required this.firestore,
    required this.auth,
  });

  User get _currentUser {
    final user = auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message:
            'A signed-in ParchApp user is required.',
      );
    }

    return user;
  }

  String get _uid =>
      _currentUser.uid;

  DocumentReference<
          Map<String, dynamic>>
      get _scheduleDocument {
    return firestore
        .collection('schedules')
        .doc(_uid);
  }

  CollectionReference<
          Map<String, dynamic>>
      get _slotsCollection {
    return _scheduleDocument
        .collection('slots');
  }

  @override
  Future<List<ScheduleBlock>>
      getMySchedule({
    required DateTime day,
  }) async {
    final dayKey =
        _dayKey(day);

    final snapshot =
        await _slotsCollection
            .where(
              'dayKey',
              isEqualTo: dayKey,
            )
            .get();

    final blocks =
        snapshot.docs
            .map(
              _scheduleBlockFromDocument,
            )
            .toList();

    blocks.sort(
      (first, second) =>
          first.start.compareTo(
        second.start,
      ),
    );

    return blocks;
  }

  ScheduleBlock
      _scheduleBlockFromDocument(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final data =
        document.data();

    final start =
        data['start'];

    final end =
        data['end'];

    if (start is! Timestamp ||
        end is! Timestamp) {
      throw StateError(
        'Invalid schedule slot ${document.id}.',
      );
    }

    return ScheduleBlock(
      id: document.id,
      start:
          start.toDate().toLocal(),
      end:
          end.toDate().toLocal(),
      type:
          ScheduleBlockType
              .personalEvent,
      title:
          data['title'] as String?,
      subtitle:
          data['description']
              as String?,
      location:
          data['location']
              as String?,
      ownerId: _uid,
    );
  }

  @override
  Future<void>
      replaceImportedCalendarBlocks(
    List<ScheduleBlock> blocks,
  ) async {
    final existing =
        await _slotsCollection.get();

    final deleteOperations =
        existing.docs
            .map(
              (document) =>
                  _ScheduleWriteOperation
                      .delete(
                document.reference,
              ),
            )
            .toList();

    await _commitOperations(
      deleteOperations,
    );

    final writeOperations =
        blocks.map(
      (block) {
        final documentId =
            _safeDocumentId(
          block.id,
        );

        final reference =
            _slotsCollection.doc(
          documentId,
        );

        final data =
            <String, dynamic>{
          'externalId':
              _externalId(
            block.id,
          ),
          'title':
              block.title ?? '',
          'start':
              Timestamp.fromDate(
            block.start,
          ),
          'end':
              Timestamp.fromDate(
            block.end,
          ),
          'dayKey':
              _dayKey(
            block.start,
          ),
          'source':
              'google_calendar',
          'importedAt':
              FieldValue
                  .serverTimestamp(),
        };

        final description =
            block.subtitle;

        if (description != null &&
            description.trim().isNotEmpty) {
          data['description'] =
              description.trim();
        }

        final location =
            block.location;

        if (location != null &&
            location.trim().isNotEmpty) {
          data['location'] =
              location.trim();
        }

        return _ScheduleWriteOperation
            .set(
          reference,
          data,
        );
      },
    ).toList();

    await _commitOperations(
      writeOperations,
    );

    await _scheduleDocument.set(
      {
        'ownerId': _uid,
        'source':
            'google_calendar',
        'lastImportedAt':
            FieldValue
                .serverTimestamp(),
        'importedCount':
            blocks.length,
      },
    );
  }

  @override
  Future<List<ScheduleFriend>>
      getFriends() async {
    final groups =
        await firestore
            .collection('groups')
            .where(
              'memberIds',
              arrayContains: _uid,
            )
            .get();

    final friends =
        <String, ScheduleFriend>{};

    for (final group
        in groups.docs) {
      final members =
          group.data()['members'];

      if (members is! List) {
        continue;
      }

      for (final rawMember
          in members) {
        if (rawMember is! Map) {
          continue;
        }

        final member =
            Map<String, dynamic>.from(
          rawMember,
        );

        final id =
            member['id'];

        if (id is! String ||
            id == _uid) {
          continue;
        }

        final name =
            member['name']
                    as String? ??
                'Friend';

        friends[id] =
            ScheduleFriend(
          id: id,
          name: name,
          fullName: name,
          initials:
              member['initials']
                      as String? ??
                  _initials(name),
        );
      }
    }

    final result =
        friends.values.toList();

    result.sort(
      (first, second) =>
          first.name.compareTo(
        second.name,
      ),
    );

    return result;
  }

  @override
  Future<List<ScheduleBlock>>
      getFriendsBusyBlocks({
    required DateTime day,
    required List<String> friendIds,
  }) async {
    if (friendIds.isEmpty) {
      return [];
    }

    //
    // The current backend contract stores group busy
    // information for today only.
    //
    if (!_sameDay(
      day,
      DateTime.now(),
    )) {
      return [];
    }

    final groups =
        await firestore
            .collection('groups')
            .where(
              'memberIds',
              arrayContains: _uid,
            )
            .get();

    final blocks =
        <ScheduleBlock>[];

    final uniqueBlocks =
        <String>{};

    for (final group
        in groups.docs) {
      final members =
          group.data()['members'];

      if (members is! List) {
        continue;
      }

      for (final rawMember
          in members) {
        if (rawMember is! Map) {
          continue;
        }

        final member =
            Map<String, dynamic>.from(
          rawMember,
        );

        final friendId =
            member['id'];

        if (friendId is! String ||
            !friendIds.contains(
              friendId,
            )) {
          continue;
        }

        final busy =
            member['busy'];

        if (busy is! List) {
          continue;
        }

        for (var index = 0;
            index < busy.length;
            index++) {
          final rawInterval =
              busy[index];

          if (rawInterval is! Map) {
            continue;
          }

          final interval =
              Map<String, dynamic>.from(
            rawInterval,
          );

          final startMinutes =
              interval['start'];

          final endMinutes =
              interval['end'];

          if (startMinutes is! int ||
              endMinutes is! int ||
              startMinutes < 0 ||
              endMinutes > 1440 ||
              startMinutes >=
                  endMinutes) {
            continue;
          }

          final key =
              '$friendId-$startMinutes-$endMinutes';

          if (!uniqueBlocks.add(key)) {
            continue;
          }

          blocks.add(
            ScheduleBlock(
              id:
                  'friend-$friendId-$startMinutes-$endMinutes',
              ownerId:
                  friendId,
              start:
                  _dateFromMinutes(
                day,
                startMinutes,
              ),
              end:
                  _dateFromMinutes(
                day,
                endMinutes,
              ),
              type:
                  ScheduleBlockType
                      .friendBusy,
            ),
          );
        }
      }
    }

    return blocks;
  }

  Future<void> _commitOperations(
    List<_ScheduleWriteOperation>
        operations,
  ) async {
    const maximumOperations =
        400;

    for (var start = 0;
        start < operations.length;
        start += maximumOperations) {
      final end =
          start +
                      maximumOperations >
                  operations.length
              ? operations.length
              : start +
                  maximumOperations;

      final batch =
          firestore.batch();

      final chunk =
          operations.sublist(
        start,
        end,
      );

      for (final operation
          in chunk) {
        operation.apply(batch);
      }

      await batch.commit();
    }
  }

  DateTime _dateFromMinutes(
    DateTime day,
    int minutes,
  ) {
    final startOfDay =
        DateTime(
      day.year,
      day.month,
      day.day,
    );

    return startOfDay.add(
      Duration(
        minutes: minutes,
      ),
    );
  }

  String _dayKey(
    DateTime date,
  ) {
    final local =
        date.toLocal();

    final month =
        local.month
            .toString()
            .padLeft(2, '0');

    final day =
        local.day
            .toString()
            .padLeft(2, '0');

    return '${local.year}-$month-$day';
  }

  String _safeDocumentId(
    String id,
  ) {
    return id
        .replaceAll('/', '_')
        .replaceAll('\\', '_');
  }

  String _externalId(
    String blockId,
  ) {
    const prefix =
        'google-';

    if (blockId.startsWith(
      prefix,
    )) {
      return blockId.substring(
        prefix.length,
      );
    }

    return blockId;
  }

  String _initials(
    String name,
  ) {
    final words =
        name
            .trim()
            .split(
              RegExp(r'\s+'),
            )
            .where(
              (word) =>
                  word.isNotEmpty,
            )
            .toList();

    return words
        .take(2)
        .map(
          (word) =>
              word[0].toUpperCase(),
        )
        .join();
  }

  bool _sameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }
}

class _ScheduleWriteOperation {
  final DocumentReference<
      Map<String, dynamic>> reference;

  final Map<String, dynamic>?
      data;

  final bool isDelete;

  const _ScheduleWriteOperation._({
    required this.reference,
    required this.isDelete,
    this.data,
  });

  factory _ScheduleWriteOperation.set(
    DocumentReference<
            Map<String, dynamic>>
        reference,
    Map<String, dynamic> data,
  ) {
    return _ScheduleWriteOperation._(
      reference: reference,
      data: data,
      isDelete: false,
    );
  }

  factory _ScheduleWriteOperation.delete(
    DocumentReference<
            Map<String, dynamic>>
        reference,
  ) {
    return _ScheduleWriteOperation._(
      reference: reference,
      isDelete: true,
    );
  }

  void apply(
    WriteBatch batch,
  ) {
    if (isDelete) {
      batch.delete(reference);
      return;
    }

    batch.set(
      reference,
      data!,
    );
  }
}