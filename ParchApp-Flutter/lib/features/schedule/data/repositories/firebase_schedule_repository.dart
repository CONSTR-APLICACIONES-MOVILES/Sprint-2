import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/schedule_block.dart';
import '../../domain/entities/schedule_friend.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/schedule_repository.dart';

class FirebaseScheduleRepository implements ScheduleRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const FirebaseScheduleRepository({
    required this.firestore,
    required this.auth,
  });

  // ===================================================================
  // CURRENT USER
  // ===================================================================

  User get _currentUser {
    final user = auth.currentUser;

    if (user == null) {
      throw StateError(
        'No authenticated Firebase user.',
      );
    }

    return user;
  }

  String get _uid => _currentUser.uid;

  // ===================================================================
  // FIRESTORE REFERENCES
  // ===================================================================

  DocumentReference<Map<String, dynamic>> get _scheduleDocument =>
      firestore.collection('schedules').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _slotsCollection =>
      _scheduleDocument.collection('slots');

  DocumentReference<Map<String, dynamic>> get _availabilityDocument =>
      firestore.collection('availability').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _availabilitySlotsCollection =>
      _availabilityDocument.collection('slots');

  // ===================================================================
  // FRIENDS
  // ===================================================================

  @override
  Future<List<ScheduleFriend>> getFriends() async {
    final currentUid = _uid;

    debugPrint(
      'FRIENDS -> Loading accepted friends for $currentUid',
    );

    // -----------------------------------------------------------------
    // 1. Read the relationships of the authenticated user.
    //
    // users/{currentUid}/friends
    // -----------------------------------------------------------------

    final friendshipSnapshot = await firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .where(
          'status',
          isEqualTo: 'accepted',
        )
        .get();

    debugPrint(
      'FRIENDS -> '
      '${friendshipSnapshot.docs.length} accepted relationships found',
    );

    if (friendshipSnapshot.docs.isEmpty) {
      return const [];
    }

    final friends = <ScheduleFriend>[];

    // -----------------------------------------------------------------
    // 2. Load each friend's public/basic profile.
    //
    // users/{friendId}
    // -----------------------------------------------------------------

    for (final friendshipDocument in friendshipSnapshot.docs) {
      final relationshipData =
          friendshipDocument.data();

      final rawFriendId =
          relationshipData['friendId'];

      final friendId =
          rawFriendId is String &&
                  rawFriendId.trim().isNotEmpty
              ? rawFriendId.trim()
              : friendshipDocument.id;

      debugPrint(
        'FRIENDS -> Reading users/$friendId',
      );

      final friendSnapshot = await firestore
          .collection('users')
          .doc(friendId)
          .get();

      if (!friendSnapshot.exists) {
        debugPrint(
          'FRIENDS -> '
          'users/$friendId does not exist',
        );

        continue;
      }

      final data =
          friendSnapshot.data();

      if (data == null) {
        continue;
      }

      final rawName =
          data['name'];

      final rawFullName =
          data['fullName'];

      final rawInitials =
          data['initials'];

      final name =
          rawName is String
              ? rawName.trim()
              : '';

      final fullName =
          rawFullName is String
              ? rawFullName.trim()
              : '';

      final initials =
          rawInitials is String
              ? rawInitials.trim()
              : '';

      final resolvedName =
          name.isNotEmpty
              ? name
              : fullName.isNotEmpty
                  ? fullName
                      .split(
                        RegExp(r'\s+'),
                      )
                      .first
                  : friendId;

      final resolvedFullName =
          fullName.isNotEmpty
              ? fullName
              : resolvedName;

      final resolvedInitials =
          initials.isNotEmpty
              ? initials
              : _initials(
                  resolvedFullName,
                );

      friends.add(
        ScheduleFriend(
          id: friendId,
          name: resolvedName,
          fullName: resolvedFullName,
          initials: resolvedInitials,
        ),
      );
    }

    // -----------------------------------------------------------------
    // 3. Sort alphabetically.
    // -----------------------------------------------------------------

    friends.sort(
      (a, b) => a.fullName
          .toLowerCase()
          .compareTo(
            b.fullName.toLowerCase(),
          ),
    );

    debugPrint(
      'FRIENDS -> '
      '${friends.length} friend profiles loaded',
    );

    for (final friend in friends) {
      debugPrint(
        'FRIENDS -> '
        '${friend.id} | '
        '${friend.fullName}',
      );
    }

    return friends;
  }

  // ===================================================================
  // FRIEND LOCATIONS
  // ===================================================================

  @override
  Future<Map<String, UserLocation>> getFriendLocations({
    required List<String> friendIds,
  }) async {
    if (friendIds.isEmpty) {
      debugPrint(
        'FRIEND LOCATIONS -> No friend IDs received',
      );

      return const {};
    }

    debugPrint(
      'FRIEND LOCATIONS -> '
      'Loading ${friendIds.length} locations',
    );

    final result =
        <String, UserLocation>{};

    for (final friendId in friendIds) {
      debugPrint(
        'FRIEND LOCATIONS -> '
        'Reading locations/$friendId',
      );

      final snapshot = await firestore
          .collection('locations')
          .doc(friendId)
          .get();

      if (!snapshot.exists) {
        debugPrint(
          'FRIEND LOCATIONS -> '
          'No location document for $friendId',
        );

        continue;
      }

      final data =
          snapshot.data();

      if (data == null) {
        continue;
      }

      final rawLocation =
          data['location'];

      if (rawLocation is! GeoPoint) {
        debugPrint(
          'FRIEND LOCATIONS -> '
          '$friendId does not contain a valid GeoPoint',
        );

        continue;
      }

      final location =
          UserLocation(
        latitude:
            rawLocation.latitude,
        longitude:
            rawLocation.longitude,
      );

      result[friendId] =
          location;

      debugPrint(
        'FRIEND LOCATIONS -> '
        '$friendId = '
        '${location.latitude}, '
        '${location.longitude}',
      );
    }

    debugPrint(
      'FRIEND LOCATIONS -> '
      '${result.length} valid locations loaded',
    );

    return result;
  }

  // ===================================================================
  // MY PRIVATE SCHEDULE
  // ===================================================================

  @override
  Future<List<ScheduleBlock>> getMySchedule({
    required DateTime day,
  }) async {
    final dayKey =
        _dayKey(day);

    debugPrint(
      'MY SCHEDULE -> '
      'Reading schedules/$_uid/slots '
      'for $dayKey',
    );

    final snapshot = await _slotsCollection
        .where(
          'dayKey',
          isEqualTo: dayKey,
        )
        .get();

    debugPrint(
      'MY SCHEDULE -> '
      '${snapshot.docs.length} slots found',
    );

    final blocks =
        <ScheduleBlock>[];

    for (final document in snapshot.docs) {
      final data =
          document.data();

      final rawStart =
          data['start'];

      final rawEnd =
          data['end'];

      if (rawStart is! Timestamp ||
          rawEnd is! Timestamp) {
        debugPrint(
          'MY SCHEDULE -> '
          'Skipping ${document.id}: '
          'invalid timestamps',
        );

        continue;
      }

      final start =
          rawStart.toDate().toLocal();

      final end =
          rawEnd.toDate().toLocal();

      if (!end.isAfter(start)) {
        debugPrint(
          'MY SCHEDULE -> '
          'Skipping ${document.id}: '
          'end <= start',
        );

        continue;
      }

      final rawTitle =
          data['title'];

      final rawDescription =
          data['description'];

      final rawLocation =
          data['location'];

      blocks.add(
        ScheduleBlock(
          id:
              document.id,

          start:
              start,

          end:
              end,

          type:
              ScheduleBlockType.personalEvent,

          title:
              rawTitle is String
                  ? rawTitle
                  : null,

          subtitle:
              rawDescription is String
                  ? rawDescription
                  : null,

          location:
              rawLocation is String
                  ? rawLocation
                  : null,

          ownerId:
              _uid,
        ),
      );
    }

    blocks.sort(
      (a, b) =>
          a.start.compareTo(
        b.start,
      ),
    );

    return blocks;
  }

  // ===================================================================
  // FRIEND BUSY BLOCKS
  // ===================================================================

  @override
  Future<List<ScheduleBlock>> getFriendsBusyBlocks({
    required DateTime day,
    required List<String> friendIds,
  }) async {
    if (friendIds.isEmpty) {
      debugPrint(
        'FRIEND BUSY -> No friends selected',
      );

      return const [];
    }

    final dayKey =
        _dayKey(day);

    debugPrint(
      'FRIEND BUSY -> '
      'Loading $dayKey '
      'for friends=$friendIds',
    );

    final blocks =
        <ScheduleBlock>[];

    for (final friendId in friendIds) {
      debugPrint(
        'FRIEND BUSY -> '
        'Reading availability/$friendId/slots',
      );

      // ---------------------------------------------------------------
      // PRIVACY:
      //
      // DO NOT read:
      //
      // schedules/{friendId}/slots
      //
      // because that collection has the friend's private:
      //
      // title
      // description
      // location
      //
      // Instead we only use:
      //
      // availability/{friendId}/slots
      //
      // containing:
      //
      // start
      // end
      // dayKey
      // ---------------------------------------------------------------

      final snapshot = await firestore
          .collection('availability')
          .doc(friendId)
          .collection('slots')
          .where(
            'dayKey',
            isEqualTo: dayKey,
          )
          .get();

      debugPrint(
        'FRIEND BUSY -> '
        '$friendId has '
        '${snapshot.docs.length} busy slots',
      );

      for (final document in snapshot.docs) {
        final data =
            document.data();

        final rawStart =
            data['start'];

        final rawEnd =
            data['end'];

        if (rawStart is! Timestamp ||
            rawEnd is! Timestamp) {
          debugPrint(
            'FRIEND BUSY -> '
            'Skipping ${document.id}: '
            'invalid timestamps',
          );

          continue;
        }

        final start =
            rawStart.toDate().toLocal();

        final end =
            rawEnd.toDate().toLocal();

        if (!end.isAfter(start)) {
          continue;
        }

        blocks.add(
          ScheduleBlock(
            id:
                '$friendId-${document.id}',

            start:
                start,

            end:
                end,

            type:
                ScheduleBlockType.friendBusy,

            // ---------------------------------------------------------
            // We only know that this period is busy.
            //
            // We intentionally never expose the friend's event title.
            // ---------------------------------------------------------

            title:
                'Busy',

            subtitle:
                null,

            location:
                null,

            ownerId:
                friendId,
          ),
        );
      }
    }

    blocks.sort(
      (a, b) {
        final startComparison =
            a.start.compareTo(
          b.start,
        );

        if (startComparison != 0) {
          return startComparison;
        }

        return (a.ownerId ?? '')
            .compareTo(
          b.ownerId ?? '',
        );
      },
    );

    debugPrint(
      'FRIEND BUSY -> '
      '${blocks.length} total busy blocks loaded',
    );

    return blocks;
  }

  // ===================================================================
  // GOOGLE CALENDAR SYNCHRONIZATION
  // ===================================================================

  @override
  Future<void> replaceImportedCalendarBlocks(
    List<ScheduleBlock> blocks,
  ) async {
    final uid =
        _uid;

    final now =
        Timestamp.now();

    debugPrint(
      'FIRESTORE SAVE -> '
      'Synchronizing ${blocks.length} Google Calendar blocks',
    );

    // -----------------------------------------------------------------
    // 1. DELETE PREVIOUS GOOGLE CALENDAR PRIVATE SLOTS
    // -----------------------------------------------------------------

    final previousPrivate = await _slotsCollection
        .where(
          'source',
          isEqualTo: 'google_calendar',
        )
        .get();

    debugPrint(
      'FIRESTORE SAVE -> '
      'Deleting ${previousPrivate.docs.length} '
      'previous private Google slots',
    );

    for (final document in previousPrivate.docs) {
      await document.reference.delete();
    }

    // -----------------------------------------------------------------
    // 2. DELETE PREVIOUS SHARED AVAILABILITY
    //
    // This projection contains no private metadata.
    // -----------------------------------------------------------------

    final previousAvailability =
        await _availabilitySlotsCollection
            .get();

    debugPrint(
      'FIRESTORE SAVE -> '
      'Deleting ${previousAvailability.docs.length} '
      'previous availability slots',
    );

    for (final document in previousAvailability.docs) {
      await document.reference.delete();
    }

    // -----------------------------------------------------------------
    // 3. WRITE CURRENT GOOGLE CALENDAR
    // -----------------------------------------------------------------

    var writtenCount =
        0;

    for (final block in blocks) {
      if (!block.end.isAfter(block.start)) {
        debugPrint(
          'FIRESTORE SAVE -> '
          'Skipping ${block.id}: invalid interval',
        );

        continue;
      }

      final documentId =
          _safeDocumentId(
        block.id,
      );

      // ---------------------------------------------------------------
      // PRIVATE DATA
      // ---------------------------------------------------------------

      final privateData =
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
            now,
      };

      if (block.subtitle != null &&
          block.subtitle!
              .trim()
              .isNotEmpty) {
        privateData['description'] =
            block.subtitle!.trim();
      }

      if (block.location != null &&
          block.location!
              .trim()
              .isNotEmpty) {
        privateData['location'] =
            block.location!.trim();
      }

      // ---------------------------------------------------------------
      // schedules/{uid}/slots/{slotId}
      //
      // PRIVATE VERSION
      // ---------------------------------------------------------------

      await _slotsCollection
          .doc(documentId)
          .set(
        privateData,
      );

      // ---------------------------------------------------------------
      // availability/{uid}/slots/{slotId}
      //
      // PRIVACY-SAFE VERSION
      //
      // ONLY:
      //
      // start
      // end
      // dayKey
      // ---------------------------------------------------------------

      await _availabilitySlotsCollection
          .doc(documentId)
          .set({
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
      });

      writtenCount++;

      debugPrint(
        'FIRESTORE SAVE -> '
        'Wrote slot $documentId',
      );
    }

    // -----------------------------------------------------------------
    // 4. PRIVATE SCHEDULE PARENT
    // -----------------------------------------------------------------

    await _scheduleDocument.set(
      {
        'ownerId':
            uid,

        'source':
            'google_calendar',

        'lastImportedAt':
            now,

        'importedCount':
            writtenCount,
      },
      SetOptions(
        merge: true,
      ),
    );

    // -----------------------------------------------------------------
    // 5. AVAILABILITY PARENT
    // -----------------------------------------------------------------

    await _availabilityDocument.set(
      {
        'ownerId':
            uid,

        'slotCount':
            writtenCount,

        'updatedAt':
            now,
      },
      SetOptions(
        merge: true,
      ),
    );

    debugPrint(
      'FIRESTORE SAVE -> '
      'Synchronization completed',
    );

    debugPrint(
      'FIRESTORE SAVE -> '
      '$writtenCount private slots',
    );

    debugPrint(
      'FIRESTORE SAVE -> '
      '$writtenCount shared availability slots',
    );
  }

  // ===================================================================
  // HELPERS
  // ===================================================================

  String _dayKey(
    DateTime value,
  ) {
    final local =
        value.toLocal();

    final year =
        local.year
            .toString()
            .padLeft(
              4,
              '0',
            );

    final month =
        local.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final day =
        local.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }

  String _safeDocumentId(
    String value,
  ) {
    return value
        .replaceAll(
          '/',
          '_',
        )
        .replaceAll(
          '\\',
          '_',
        );
  }

  String _externalId(
    String value,
  ) {
    const prefix =
        'google-';

    if (value.startsWith(prefix)) {
      return value.substring(
        prefix.length,
      );
    }

    return value;
  }

  String _initials(
    String name,
  ) {
    final words = name
        .trim()
        .split(
          RegExp(r'\s+'),
        )
        .where(
          (word) =>
              word.isNotEmpty,
        )
        .toList();

    if (words.isEmpty) {
      return '?';
    }

    if (words.length == 1) {
      return words.first
          .substring(
            0,
            1,
          )
          .toUpperCase();
    }

    return (
      words.first.substring(
            0,
            1,
          ) +
      words.last.substring(
            0,
            1,
          )
    ).toUpperCase();
  }
}