import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_service.dart';

import '../../features/schedule/data/adapters/google_calendar_adapter.dart';
import '../../features/schedule/data/data_sources/google_calendar_api_data_source.dart';
import '../../features/schedule/data/data_sources/google_calendar_auth_data_source.dart';
import '../../features/schedule/data/repositories/calendar_import_repository_impl.dart';
import '../../features/schedule/data/repositories/firebase_schedule_repository.dart';
import '../../features/schedule/data/repositories/geolocator_location_repository.dart';
import '../../features/schedule/data/repositories/local_schedule_cache_metadata_repository.dart';
import '../../features/schedule/data/repositories/local_schedule_preferences_repository.dart';

import '../../features/schedule/domain/repositories/calendar_import_repository.dart';
import '../../features/schedule/domain/repositories/schedule_cache_metadata_repository.dart';
import '../../features/schedule/domain/repositories/schedule_preferences_repository.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';

import '../../features/schedule/domain/services/availability_service.dart';
import '../../features/schedule/domain/services/distance_service.dart';

import '../../features/schedule/domain/use_cases/authorize_google_calendar.dart';
import '../../features/schedule/domain/use_cases/get_schedule_preferences.dart';
import '../../features/schedule/domain/use_cases/import_google_calendar.dart';
import '../../features/schedule/domain/use_cases/manage_schedule.dart';
import '../../features/schedule/domain/use_cases/save_schedule_preferences.dart';

import '../../features/schedule/presentation/view_models/schedule_view_model.dart';
import '../../features/schedule/presentation/views/schedule_view.dart';

import 'firebase_dependencies.dart';

class ScheduleDependencies {
  // ===================================================================
  // REPOSITORIES / SERVICES
  // ===================================================================

  final ScheduleRepository
      scheduleRepository;

  final CalendarImportRepository
      calendarImportRepository;

  final SchedulePreferencesRepository
      schedulePreferencesRepository;

  final ScheduleCacheMetadataRepository
      scheduleCacheMetadataRepository;

  final ConnectivityService
      connectivityService;

  const ScheduleDependencies._({
    required this.scheduleRepository,
    required this.calendarImportRepository,
    required this.schedulePreferencesRepository,
    required this.scheduleCacheMetadataRepository,
    required this.connectivityService,
  });

  // ===================================================================
  // FIREBASE / DATA IMPLEMENTATION
  // ===================================================================

  factory ScheduleDependencies.firebase(
    FirebaseDependencies firebase,
  ) {
    // -----------------------------------------------------------------
    // GOOGLE CALENDAR AUTH
    // -----------------------------------------------------------------

    final googleAuthDataSource =
        GoogleCalendarAuthDataSource();

    // -----------------------------------------------------------------
    // GOOGLE CALENDAR API
    // -----------------------------------------------------------------

    final googleCalendarDataSource =
        GoogleCalendarApiDataSource(
      authDataSource:
          googleAuthDataSource,
    );

    // -----------------------------------------------------------------
    // FIREBASE SCHEDULE REPOSITORY
    //
    // Handles:
    //
    // schedules/{uid}
    // schedules/{uid}/slots
    // availability/{uid}
    // availability/{uid}/slots
    // friends
    // locations
    // -----------------------------------------------------------------

    final scheduleRepository =
        FirebaseScheduleRepository(
      firestore:
          firebase.firestore,
      auth:
          firebase.auth,
    );

    // -----------------------------------------------------------------
    // LOCAL QUICK-DURATION PREFERENCES
    //
    // Stored locally using SharedPreferences.
    //
    // Firebase Auth is used only to obtain the current UID so that
    // preferences are separated per account.
    // -----------------------------------------------------------------

    final preferencesRepository =
        LocalSchedulePreferencesRepository(
      auth:
          firebase.auth,
    );

    // -----------------------------------------------------------------
    // LOCAL SCHEDULE CACHE METADATA
    //
    // Stores only metadata such as:
    //
    // last successful Schedule synchronization time.
    //
    // The schedule documents themselves are cached by Firestore.
    // -----------------------------------------------------------------

    final cacheMetadataRepository =
        LocalScheduleCacheMetadataRepository(
      auth:
          firebase.auth,
    );

    // -----------------------------------------------------------------
    // CONNECTIVITY
    // -----------------------------------------------------------------

    final connectivityService =
        ConnectivityService();

    // -----------------------------------------------------------------
    // GOOGLE CALENDAR IMPORT REPOSITORY
    // -----------------------------------------------------------------

    final calendarImportRepository =
        CalendarImportRepositoryImpl(
      dataSource:
          googleCalendarDataSource,

      authDataSource:
          googleAuthDataSource,

      adapter:
          const GoogleCalendarAdapter(),
    );

    // -----------------------------------------------------------------
    // CREATE DEPENDENCY CONTAINER
    // -----------------------------------------------------------------

    return ScheduleDependencies._(
      scheduleRepository:
          scheduleRepository,

      calendarImportRepository:
          calendarImportRepository,

      schedulePreferencesRepository:
          preferencesRepository,

      scheduleCacheMetadataRepository:
          cacheMetadataRepository,

      connectivityService:
          connectivityService,
    );
  }

  // ===================================================================
  // VIEW MODEL
  // ===================================================================

  ScheduleViewModel createViewModel() {
    // -----------------------------------------------------------------
    // LOCATION
    // -----------------------------------------------------------------

    const locationRepository =
        GeolocatorLocationRepository();

    // -----------------------------------------------------------------
    // DOMAIN SERVICES
    // -----------------------------------------------------------------

    const availabilityService =
        AvailabilityService();

    const distanceService =
        DistanceService();

    // -----------------------------------------------------------------
    // MANAGE SCHEDULE
    // -----------------------------------------------------------------

    final manageSchedule =
        ManageSchedule(
      scheduleRepository,
      availabilityService,
      locationRepository,
      distanceService,
    );

    // -----------------------------------------------------------------
    // GOOGLE CALENDAR IMPORT
    // -----------------------------------------------------------------

    final importGoogleCalendar =
        ImportGoogleCalendar(
      calendarImportRepository,
      scheduleRepository,
    );

    // -----------------------------------------------------------------
    // GOOGLE CALENDAR AUTHORIZATION
    // -----------------------------------------------------------------

    final authorizeGoogleCalendar =
        AuthorizeGoogleCalendar(
      calendarImportRepository,
    );

    // -----------------------------------------------------------------
    // LOCAL QUICK-DURATION PREFERENCES
    // -----------------------------------------------------------------

    final getSchedulePreferences =
        GetSchedulePreferences(
      schedulePreferencesRepository,
    );

    final saveSchedulePreferences =
        SaveSchedulePreferences(
      schedulePreferencesRepository,
    );

    // -----------------------------------------------------------------
    // SCHEDULE VIEW MODEL
    // -----------------------------------------------------------------

    return ScheduleViewModel(
      manageSchedule,
      importGoogleCalendar,

      authorizeGoogleCalendar:
          authorizeGoogleCalendar,

      getSchedulePreferences:
          getSchedulePreferences,

      saveSchedulePreferences:
          saveSchedulePreferences,

      connectivityService:
          connectivityService,

      cacheMetadataRepository:
          scheduleCacheMetadataRepository,
    );
  }

  // ===================================================================
  // ROUTE
  // ===================================================================

  Widget route() {
    return _ScheduleEntry(
      dependencies:
          this,
    );
  }
}

// =====================================================================
// SCHEDULE ENTRY
// =====================================================================
//
// Creates the ViewModel once when the Schedule route is mounted.
//
// This prevents the ViewModel from being recreated every time
// ScheduleView rebuilds.
// =====================================================================

class _ScheduleEntry
    extends StatefulWidget {
  final ScheduleDependencies
      dependencies;

  const _ScheduleEntry({
    required this.dependencies,
  });

  @override
  State<_ScheduleEntry> createState() =>
      _ScheduleEntryState();
}

class _ScheduleEntryState
    extends State<_ScheduleEntry> {
  late final ScheduleViewModel
      _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel =
        widget.dependencies
            .createViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ScheduleView(
      viewModel:
          _viewModel,
    );
  }
}