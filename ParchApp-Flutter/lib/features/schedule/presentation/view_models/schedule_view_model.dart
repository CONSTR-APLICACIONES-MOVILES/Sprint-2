import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/connectivity/connectivity_service.dart';

import '../../domain/entities/common_slot.dart';

import '../../domain/repositories/schedule_cache_metadata_repository.dart';

import '../../domain/use_cases/authorize_google_calendar.dart';
import '../../domain/use_cases/import_google_calendar.dart';
import '../../domain/use_cases/manage_schedule.dart';
import '../../domain/use_cases/get_schedule_preferences.dart';
import '../../domain/use_cases/save_schedule_preferences.dart';

import 'schedule_state.dart';

class ScheduleViewModel
    extends ValueNotifier<ScheduleState> {
  final ManageSchedule _schedule;

  final AuthorizeGoogleCalendar
      _authorizeGoogleCalendar;

  final ImportGoogleCalendar
      _importGoogleCalendar;

  final GetSchedulePreferences
      _getSchedulePreferences;

  final SaveSchedulePreferences
      _saveSchedulePreferences;

  final ConnectivityService
      _connectivityService;

  final ScheduleCacheMetadataRepository
      _cacheMetadataRepository;

  StreamSubscription<bool>?
      _connectivitySubscription;

  bool _connectivityMonitoringStarted =
      false;

  bool _disposed = false;

  ScheduleViewModel(
    this._schedule,
    this._importGoogleCalendar, {
    required AuthorizeGoogleCalendar
        authorizeGoogleCalendar,
    required GetSchedulePreferences
        getSchedulePreferences,
    required SaveSchedulePreferences
        saveSchedulePreferences,
    required ConnectivityService
        connectivityService,
    required ScheduleCacheMetadataRepository
        cacheMetadataRepository,
    DateTime? initialDay,
  })  : _authorizeGoogleCalendar =
            authorizeGoogleCalendar,
        _getSchedulePreferences =
            getSchedulePreferences,
        _saveSchedulePreferences =
            saveSchedulePreferences,
        _connectivityService =
            connectivityService,
        _cacheMetadataRepository =
            cacheMetadataRepository,
        super(
          ScheduleState(
            selectedDay: _dateOnly(
              initialDay ??
                  DateTime.now(),
            ),
          ),
        );

  // ===================================================================
  // INITIAL LOAD
  // ===================================================================

  Future<void> load() async {
    _startConnectivityMonitoring();

    _emit(
      value.copyWith(
        status:
            ScheduleLoadStatus.loading,
        clearError: true,
      ),
    );

    // ---------------------------------------------------------------
    // 0. LOCAL QUICK-DURATION PREFERENCES
    //
    // These are local and must not prevent Schedule from loading.
    // ---------------------------------------------------------------

    await loadSchedulePreferences();

    // ---------------------------------------------------------------
    // LOAD CACHE METADATA FOR CURRENT DAY
    // ---------------------------------------------------------------

    DateTime? lastUpdated;

    try {
      lastUpdated =
          await _cacheMetadataRepository
              .getLastUpdated(
        value.selectedDay,
      );

      _emit(
        value.copyWith(
          scheduleLastUpdatedAt:
              lastUpdated,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'SCHEDULE CACHE -> '
        'Unable to load metadata: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }

    try {
      // -------------------------------------------------------------
      // 1. LOAD FRIENDS
      //
      // users/{currentUid}/friends
      // +
      // users/{friendId}
      // -------------------------------------------------------------

      debugPrint(
        'SCHEDULE VM -> '
        'Loading friends...',
      );

      final friends =
          await _schedule.loadFriends();

      debugPrint(
        'SCHEDULE VM -> '
        '${friends.length} friends loaded',
      );

      // -------------------------------------------------------------
      // 2. REMOVE INVALID OLD SELECTIONS
      // -------------------------------------------------------------

      final validFriendIds =
          friends
              .map(
                (friend) => friend.id,
              )
              .toSet();

      final selectedFriendIds =
          value.selectedFriendIds
              .where(
                validFriendIds.contains,
              )
              .toList();

      _emit(
        value.copyWith(
          friends:
              friends,
          selectedFriendIds:
              selectedFriendIds,
        ),
      );

      // -------------------------------------------------------------
      // 3. GPS / NEARBY FRIENDS
      //
      // Failure here must not break Schedule.
      // -------------------------------------------------------------

      await loadNearbyFriends();

      // -------------------------------------------------------------
      // 4. CURRENT DAY
      // -------------------------------------------------------------

      await _refreshDay();
    } catch (error, stackTrace) {
      debugPrint(
        'SCHEDULE VM -> '
        'load error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      final hasConnection =
          await _safeHasConnection();

      // -------------------------------------------------------------
      // FIRST USE + OFFLINE + NO CACHE
      // -------------------------------------------------------------

      if (!hasConnection &&
          lastUpdated == null) {
        _emit(
          value.copyWith(
            status:
                ScheduleLoadStatus.error,

            connectivityStatus:
                ScheduleConnectivityStatus
                    .offlineNoCache,

            error:
                'You are offline and there is no '
                'saved schedule available yet. '
                'Connect to the internet and retry.',
          ),
        );

        return;
      }

      // -------------------------------------------------------------
      // GENERIC FAILURE
      // -------------------------------------------------------------

      _emit(
        value.copyWith(
          status:
              ScheduleLoadStatus.error,

          error:
              _friendlyConnectivityError(
            error,
          ),
        ),
      );
    }
  }

  // ===================================================================
  // PUBLIC REFRESH
  // ===================================================================

  Future<void> refreshSchedule() async {
    if (value.isRefreshing) {
      return;
    }

    debugPrint(
      'SCHEDULE VM -> '
      'Manual/automatic refresh requested',
    );

    _emit(
      value.copyWith(
        isRefreshing:
            true,
        clearError:
            true,
      ),
    );

    try {
      await _refreshDay();
    } finally {
      _emit(
        value.copyWith(
          isRefreshing:
              false,
        ),
      );
    }
  }

  // ===================================================================
  // CONNECTIVITY MONITORING
  // ===================================================================

  void _startConnectivityMonitoring() {
    if (_connectivityMonitoringStarted) {
      return;
    }

    _connectivityMonitoringStarted =
        true;

    debugPrint(
      'SCHEDULE CONNECTIVITY -> '
      'Starting monitoring',
    );

    _connectivitySubscription =
        _connectivityService
            .connectionChanges
            .listen(
      (connected) async {
        debugPrint(
          'SCHEDULE CONNECTIVITY -> '
          'Changed: $connected',
        );

        // -----------------------------------------------------------
        // CONNECTION LOST
        // -----------------------------------------------------------

        if (!connected) {
          DateTime? lastUpdated;

          try {
            lastUpdated =
                await _cacheMetadataRepository
                    .getLastUpdated(
              value.selectedDay,
            );
          } catch (error) {
            debugPrint(
              'SCHEDULE CACHE -> '
              'Metadata error: $error',
            );
          }

          if (value.status ==
              ScheduleLoadStatus.ready) {
            _emit(
              value.copyWith(
                connectivityStatus:
                    ScheduleConnectivityStatus
                        .cached,

                scheduleLastUpdatedAt:
                    lastUpdated,
              ),
            );
          }

          return;
        }

        // -----------------------------------------------------------
        // CONNECTION RECOVERED
        // -----------------------------------------------------------

        if (value.connectivityStatus !=
            ScheduleConnectivityStatus.online) {
          debugPrint(
            'SCHEDULE CONNECTIVITY -> '
            'Connection restored. '
            'Refreshing...',
          );

          await refreshSchedule();
        }
      },
    );
  }

  // ===================================================================
  // NEARBY FRIENDS / GPS
  // ===================================================================

  Future<void> loadNearbyFriends() async {
    // ---------------------------------------------------------------
    // No friends -> nothing to calculate.
    // ---------------------------------------------------------------

    if (value.friends.isEmpty) {
      debugPrint(
        'NEARBY VM -> '
        'No friends available',
      );

      _emit(
        value.copyWith(
          nearbyFriendsStatus:
              NearbyFriendsStatus.ready,

          nearbyFriends:
              const [],

          nearbyFriendsMessage:
              'No friends available.',

          clearCurrentLocation:
              true,
        ),
      );

      return;
    }

    _emit(
      value.copyWith(
        nearbyFriendsStatus:
            NearbyFriendsStatus.loading,

        nearbyFriends:
            const [],

        clearNearbyFriendsMessage:
            true,
      ),
    );

    try {
      debugPrint(
        'NEARBY VM -> '
        'Requesting current location...',
      );

      // -------------------------------------------------------------
      // ManageSchedule:
      //
      // 1. reads device GPS
      // 2. reads locations/{friendId}
      // 3. calculates distances
      // 4. keeps nearby friends
      // -------------------------------------------------------------

      final result =
          await _schedule
              .loadNearbyFriends(
        friends:
            value.friends,
      );

      debugPrint(
        'NEARBY VM -> '
        'Current location: '
        '${result.currentLocation.latitude}, '
        '${result.currentLocation.longitude}',
      );

      debugPrint(
        'NEARBY VM -> '
        '${result.nearbyFriends.length} '
        'nearby friends',
      );

      for (final friend
          in result.nearbyFriends) {
        debugPrint(
          'NEARBY VM -> '
          '${friend.name}: '
          '${friend.distanceMeters?.toStringAsFixed(0)} m',
        );
      }

      _emit(
        value.copyWith(
          nearbyFriendsStatus:
              NearbyFriendsStatus.ready,

          nearbyFriends:
              result.nearbyFriends,

          currentLocation:
              result.currentLocation,

          nearbyFriendsMessage:
              result.nearbyFriends.isEmpty
                  ? 'No friends nearby.'
                  : '${result.nearbyFriends.length} nearby friends.',
        ),
      );
    } catch (error, stackTrace) {
      // -------------------------------------------------------------
      // GPS failure does NOT break Schedule.
      // -------------------------------------------------------------

      debugPrint(
        'NEARBY VM -> '
        'error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      _emit(
        value.copyWith(
          nearbyFriendsStatus:
              NearbyFriendsStatus.error,

          nearbyFriends:
              const [],

          nearbyFriendsMessage:
              _friendlyLocationError(
            error,
          ),

          clearCurrentLocation:
              true,
        ),
      );
    }
  }

  // ===================================================================
  // GOOGLE CALENDAR IMPORT
  // ===================================================================

  Future<void> importGoogleCalendar() async {
    if (value.calendarImportStatus ==
        CalendarImportStatus.importing) {
      return;
    }

    // ---------------------------------------------------------------
    // GOOGLE CALENDAR REQUIRES INTERNET
    // ---------------------------------------------------------------

    final hasConnection =
        await _safeHasConnection();

    if (!hasConnection) {
      debugPrint(
        'SCHEDULE VM -> '
        'Google Calendar import blocked: offline',
      );

      _emit(
        value.copyWith(
          calendarImportStatus:
              CalendarImportStatus.error,

          calendarImportMessage:
              'Google Calendar import requires '
              'an internet connection.',
        ),
      );

      return;
    }

    _emit(
      value.copyWith(
        calendarImportStatus:
            CalendarImportStatus.importing,

        calendarImportMessage:
            'Importing Google Calendar...',
      ),
    );

    try {
      // -------------------------------------------------------------
      // IMPORTANT:
      //
      // We intentionally do NOT call
      // _authorizeGoogleCalendar() here.
      //
      // The import flow already handles the authorization process
      // in the existing architecture.
      // -------------------------------------------------------------

      debugPrint(
        'SCHEDULE VM -> '
        'Authorizing Google Calendar...',
      );

      debugPrint(
        'SCHEDULE VM -> '
        'Importing Google Calendar...',
      );

      final count =
          await _importGoogleCalendar();

      debugPrint(
        'SCHEDULE VM -> '
        '$count Google Calendar '
        'events imported',
      );

      _emit(
        value.copyWith(
          calendarImportStatus:
              CalendarImportStatus.imported,

          calendarImportMessage:
              '$count Google Calendar events imported.',
        ),
      );

      // -------------------------------------------------------------
      // Imported events changed:
      //
      // schedules/{uid}/slots
      //
      // and:
      //
      // availability/{uid}/slots
      // -------------------------------------------------------------

      await _refreshDay();
    } catch (error, stackTrace) {
      debugPrint(
        'SCHEDULE VM -> '
        'Calendar import error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      _emit(
        value.copyWith(
          calendarImportStatus:
              CalendarImportStatus.error,

          calendarImportMessage:
              _friendlyConnectivityError(
            error,
          ),
        ),
      );
    }
  }

  // ===================================================================
  // DAY SELECTION
  // ===================================================================

  Future<void> selectDay(
    DateTime day,
  ) async {
    final normalized =
        _dateOnly(
      day,
    );

    if (_sameDay(
      normalized,
      value.selectedDay,
    )) {
      return;
    }

    debugPrint(
      'SCHEDULE VM -> '
      'Selected day: $normalized',
    );

    DateTime? lastUpdated;

    try {
      lastUpdated =
          await _cacheMetadataRepository
              .getLastUpdated(
        normalized,
      );
    } catch (error) {
      debugPrint(
        'SCHEDULE CACHE -> '
        'Unable to read metadata: $error',
      );
    }

    _emit(
      value.copyWith(
        selectedDay:
            normalized,

        scheduleLastUpdatedAt:
            lastUpdated,

        clearSelectedSlot:
            true,

        clearError:
            true,
      ),
    );

    await _refreshDay();
  }

  // ===================================================================
  // SCHEDULE PREFERENCES / QUICK DURATIONS
  // ===================================================================

  Future<void>
      loadSchedulePreferences() async {
    try {
      final preferences =
          await _getSchedulePreferences();

      _emit(
        value.copyWith(
          quickDurationsMinutes:
              preferences
                  .quickDurationsMinutes,
        ),
      );

      debugPrint(
        'SCHEDULE PREFS -> '
        'Loaded: '
        '${preferences.quickDurationsMinutes}',
      );
    } catch (error, stackTrace) {
      // -------------------------------------------------------------
      // Preferences are local UI settings.
      //
      // Their failure must never prevent Schedule from loading.
      // -------------------------------------------------------------

      debugPrint(
        'SCHEDULE PREFS -> '
        'Load error: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  Future<void> addQuickDuration(
    int minutes,
  ) async {
    if (minutes < 5 ||
        minutes > 240) {
      throw ArgumentError(
        'Duration must be between '
        '5 and 240 minutes.',
      );
    }

    final previous =
        List<int>.from(
      value.quickDurationsMinutes,
    );

    if (previous.length >= 4) {
      throw StateError(
        'You can have a maximum '
        'of 4 quick durations.',
      );
    }

    if (previous.contains(
      minutes,
    )) {
      throw StateError(
        'That duration already exists.',
      );
    }

    final updated = [
      ...previous,
      minutes,
    ];

    _emit(
      value.copyWith(
        quickDurationsMinutes:
            updated,
      ),
    );

    try {
      await _saveSchedulePreferences(
        updated,
      );
    } catch (error, stackTrace) {
      _emit(
        value.copyWith(
          quickDurationsMinutes:
              previous,
        ),
      );

      debugPrint(
        'SCHEDULE PREFS -> '
        'Add error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  Future<void> removeQuickDuration(
    int minutes,
  ) async {
    final previous =
        List<int>.from(
      value.quickDurationsMinutes,
    );

    final updated =
        previous
            .where(
              (item) =>
                  item != minutes,
            )
            .toList();

    if (updated.length ==
        previous.length) {
      return;
    }

    _emit(
      value.copyWith(
        quickDurationsMinutes:
            updated,
      ),
    );

    try {
      await _saveSchedulePreferences(
        updated,
      );
    } catch (error, stackTrace) {
      _emit(
        value.copyWith(
          quickDurationsMinutes:
              previous,
        ),
      );

      debugPrint(
        'SCHEDULE PREFS -> '
        'Remove error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  Future<void> editQuickDuration({
    required int oldMinutes,
    required int newMinutes,
  }) async {
    if (newMinutes < 5 ||
        newMinutes > 240) {
      throw ArgumentError(
        'Duration must be between '
        '5 and 240 minutes.',
      );
    }

    final previous =
        List<int>.from(
      value.quickDurationsMinutes,
    );

    if (!previous.contains(
      oldMinutes,
    )) {
      throw StateError(
        'The quick duration '
        'no longer exists.',
      );
    }

    if (oldMinutes != newMinutes &&
        previous.contains(
          newMinutes,
        )) {
      throw StateError(
        'That duration already exists.',
      );
    }

    final updated =
        previous
            .map(
              (minutes) =>
                  minutes ==
                          oldMinutes
                      ? newMinutes
                      : minutes,
            )
            .toList();

    final wasSelected =
        value.meetingDuration.inMinutes ==
            oldMinutes;

    _emit(
      value.copyWith(
        quickDurationsMinutes:
            updated,

        meetingDuration:
            wasSelected
                ? Duration(
                    minutes:
                        newMinutes,
                  )
                : value
                    .meetingDuration,

        clearSelectedSlot:
            wasSelected,
      ),
    );

    try {
      await _saveSchedulePreferences(
        updated,
      );

      if (wasSelected) {
        await _refreshDay();
      }
    } catch (error, stackTrace) {
      _emit(
        value.copyWith(
          quickDurationsMinutes:
              previous,

          meetingDuration:
              wasSelected
                  ? Duration(
                      minutes:
                          oldMinutes,
                    )
                  : value
                      .meetingDuration,

          clearSelectedSlot:
              wasSelected,
        ),
      );

      if (wasSelected) {
        await _refreshDay();
      }

      debugPrint(
        'SCHEDULE PREFS -> '
        'Edit error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ===================================================================
  // MEETING DURATION
  // ===================================================================

  Future<void> setDuration(
    Duration duration,
  ) async {
    if (duration.inMinutes <= 0) {
      return;
    }

    if (duration ==
        value.meetingDuration) {
      return;
    }

    debugPrint(
      'SCHEDULE VM -> '
      'Duration changed to '
      '${duration.inMinutes} minutes',
    );

    _emit(
      value.copyWith(
        meetingDuration:
            duration,

        clearSelectedSlot:
            true,
      ),
    );

    await _refreshDay();
  }

  // ===================================================================
  // FRIEND SELECTION
  // ===================================================================

  Future<void> toggleFriend(
    String friendId,
  ) async {
    final updated =
        List<String>.from(
      value.selectedFriendIds,
    );

    if (updated.contains(
      friendId,
    )) {
      updated.remove(
        friendId,
      );

      debugPrint(
        'SCHEDULE VM -> '
        'Friend removed: '
        '$friendId',
      );
    } else {
      updated.add(
        friendId,
      );

      debugPrint(
        'SCHEDULE VM -> '
        'Friend selected: '
        '$friendId',
      );
    }

    _emit(
      value.copyWith(
        selectedFriendIds:
            updated,

        clearSelectedSlot:
            true,
      ),
    );

    // ---------------------------------------------------------------
    // ManageSchedule.loadDay()
    //
    // reads:
    //
    // schedules/{currentUid}/slots
    //
    // +
    //
    // availability/{friendId}/slots
    // ---------------------------------------------------------------

    await _refreshDay();
  }

  // ===================================================================
  // COMMON SLOT SELECTION
  // ===================================================================

  void selectSlot(
    CommonSlot slot,
  ) {
    debugPrint(
      'SCHEDULE VM -> '
      'Common slot selected: '
      '${slot.start} - ${slot.end}',
    );

    _emit(
      value.copyWith(
        selectedSlot:
            slot,
      ),
    );
  }

  // ===================================================================
  // REFRESH CURRENT DAY
  // ===================================================================

  Future<void> _refreshDay() async {
    debugPrint(
      'SCHEDULE VM -> '
      'Refreshing day: '
      '${value.selectedDay}',
    );

    debugPrint(
      'SCHEDULE VM -> '
      'Selected friends: '
      '${value.selectedFriendIds}',
    );

    // ---------------------------------------------------------------
    // DETECT CURRENT CONNECTIVITY
    // ---------------------------------------------------------------

    final hasConnection =
        await _safeHasConnection();

    debugPrint(
      'SCHEDULE CONNECTIVITY -> '
      'network=$hasConnection',
    );

    // ---------------------------------------------------------------
    // READ LAST SUCCESSFUL ONLINE UPDATE
    // ---------------------------------------------------------------

    DateTime? lastUpdated;

    try {
      lastUpdated =
          await _cacheMetadataRepository
              .getLastUpdated(
        value.selectedDay,
      );
    } catch (error) {
      debugPrint(
        'SCHEDULE CACHE -> '
        'Unable to read metadata: '
        '$error',
      );
    }

    // ---------------------------------------------------------------
    // FIRST USE + OFFLINE
    //
    // No previous successful server load exists for this day.
    // ---------------------------------------------------------------

    if (!hasConnection &&
        lastUpdated == null) {
      debugPrint(
        'SCHEDULE CONNECTIVITY -> '
        'Offline with no cache',
      );

      _emit(
        value.copyWith(
          status:
              ScheduleLoadStatus.error,

          connectivityStatus:
              ScheduleConnectivityStatus
                  .offlineNoCache,

          error:
              'You are offline and there is no '
              'saved schedule for this day yet. '
              'Connect to the internet and retry.',

          clearScheduleLastUpdatedAt:
              true,

          clearSelectedSlot:
              true,
        ),
      );

      return;
    }

    try {
      // -------------------------------------------------------------
      // LOAD DAY
      //
      // ManageSchedule loads:
      //
      // schedules/{currentUid}/slots
      //
      // +
      //
      // availability/{selectedFriendId}/slots
      //
      // and calculates common free slots.
      //
      // When Firestore persistence is enabled, its local persistence
      // can satisfy reads when the server is unavailable.
      // -------------------------------------------------------------

      final result =
          await _schedule.loadDay(
        day:
            value.selectedDay,

        friendIds:
            value.selectedFriendIds,

        duration:
            value.meetingDuration,
      );

      ScheduleConnectivityStatus
          connectivityStatus;

      DateTime? resultingUpdatedAt =
          lastUpdated;

      // -------------------------------------------------------------
      // ONLINE
      // -------------------------------------------------------------

      if (hasConnection) {
        resultingUpdatedAt =
            DateTime.now();

        try {
          await _cacheMetadataRepository
              .markUpdated(
            value.selectedDay,
            resultingUpdatedAt,
          );
        } catch (error) {
          debugPrint(
            'SCHEDULE CACHE -> '
            'Unable to save timestamp: '
            '$error',
          );
        }

        connectivityStatus =
            ScheduleConnectivityStatus
                .online;

        debugPrint(
          'SCHEDULE CONNECTIVITY -> '
          'Fresh network schedule loaded',
        );
      }

      // -------------------------------------------------------------
      // OFFLINE / CACHED
      // -------------------------------------------------------------
      else {
        connectivityStatus =
            ScheduleConnectivityStatus
                .cached;

        debugPrint(
          'SCHEDULE CONNECTIVITY -> '
          'Schedule loaded from '
          'available local data/cache',
        );
      }

      debugPrint(
        'SCHEDULE VM -> '
        'My blocks: '
        '${result.myBlocks.length}',
      );

      debugPrint(
        'SCHEDULE VM -> '
        'Friend blocks: '
        '${result.friendBlocks.length}',
      );

      debugPrint(
        'SCHEDULE VM -> '
        'Common slots: '
        '${result.commonSlots.length}',
      );

      _emit(
        value.copyWith(
          status:
              ScheduleLoadStatus.ready,

          myBlocks:
              result.myBlocks,

          friendBlocks:
              result.friendBlocks,

          commonSlots:
              result.commonSlots,

          connectivityStatus:
              connectivityStatus,

          scheduleLastUpdatedAt:
              resultingUpdatedAt,

          clearSelectedSlot:
              true,

          clearError:
              true,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'SCHEDULE VM -> '
        'refresh error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      // -------------------------------------------------------------
      // FALLBACK:
      //
      // We know this day had a successful sync before.
      //
      // Preserve whatever data the UI already has rather than
      // replacing everything with a blocking error screen.
      // -------------------------------------------------------------

      if (lastUpdated != null) {
        debugPrint(
          'SCHEDULE CONNECTIVITY -> '
          'Refresh failed. '
          'Keeping saved schedule.',
        );

        _emit(
          value.copyWith(
            status:
                ScheduleLoadStatus.ready,

            connectivityStatus:
                ScheduleConnectivityStatus
                    .cached,

            scheduleLastUpdatedAt:
                lastUpdated,

            error:
                'Unable to refresh. '
                'Showing saved availability.',
          ),
        );

        return;
      }

      // -------------------------------------------------------------
      // NETWORK/CACHE BOTH FAILED
      // -------------------------------------------------------------

      _emit(
        value.copyWith(
          status:
              ScheduleLoadStatus.error,

          connectivityStatus:
              hasConnection
                  ? ScheduleConnectivityStatus
                      .online
                  : ScheduleConnectivityStatus
                      .offlineNoCache,

          error:
              _friendlyConnectivityError(
            error,
          ),

          clearSelectedSlot:
              true,
        ),
      );
    }
  }

  // ===================================================================
  // CONNECTIVITY HELPER
  // ===================================================================

  Future<bool>
      _safeHasConnection() async {
    try {
      return await _connectivityService
          .hasConnection();
    } catch (error) {
      debugPrint(
        'SCHEDULE CONNECTIVITY -> '
        'Unable to determine '
        'connectivity: $error',
      );

      // -------------------------------------------------------------
      // ConnectivityService is only a hint.
      //
      // If it fails, let Firebase become the real source of truth.
      // -------------------------------------------------------------

      return true;
    }
  }

  // ===================================================================
  // CONNECTIVITY ERROR MESSAGE
  // ===================================================================

  String _friendlyConnectivityError(
    Object error,
  ) {
    final message =
        error
            .toString()
            .toLowerCase();

    if (message.contains(
          'unavailable',
        ) ||
        message.contains(
          'network',
        ) ||
        message.contains(
          'offline',
        ) ||
        message.contains(
          'connection',
        ) ||
        message.contains(
          'socket',
        ) ||
        message.contains(
          'host lookup',
        )) {
      return 'Unable to connect to the server. '
          'Check your internet connection and retry.';
    }

    return 'Unable to load the schedule. '
        'Please try again.';
  }

  // ===================================================================
  // STATE UPDATE
  // ===================================================================

  void _emit(
    ScheduleState newState,
  ) {
    if (_disposed) {
      return;
    }

    value =
        newState;
  }

  // ===================================================================
  // DATE HELPERS
  // ===================================================================

  static DateTime _dateOnly(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  static bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year ==
            b.year &&
        a.month ==
            b.month &&
        a.day ==
            b.day;
  }

  // ===================================================================
  // LOCATION ERROR MESSAGE
  // ===================================================================

  String _friendlyLocationError(
    Object error,
  ) {
    final message =
        error.toString();

    if (message.contains(
      'Location services are disabled',
    )) {
      return 'Location services are disabled. '
          'Enable GPS to see nearby friends.';
    }

    if (message.contains(
      'permanently denied',
    )) {
      return 'Location permission is disabled '
          'in settings.';
    }

    if (message.contains(
      'permission was denied',
    )) {
      return 'Location permission was denied.';
    }

    return 'Unable to determine '
        'your current location.';
  }

  // ===================================================================
  // DISPOSE
  // ===================================================================

  @override
  void dispose() {
    _disposed =
        true;

    _connectivitySubscription
        ?.cancel();

    super.dispose();
  }
}