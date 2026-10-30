import '../../../activities/domain/entities/planning_context.dart';
import '../entities/common_slot.dart';
import '../entities/schedule_block.dart';
import '../entities/schedule_friend.dart';
import '../entities/user_location.dart';

import '../repositories/location_repository.dart';
import '../repositories/schedule_repository.dart';

import '../services/availability_service.dart';
import '../services/distance_service.dart';

class ScheduleDayResult {
  final List<ScheduleBlock> myBlocks;
  final List<ScheduleBlock> friendBlocks;
  final List<CommonSlot> commonSlots;

  const ScheduleDayResult({
    required this.myBlocks,
    required this.friendBlocks,
    required this.commonSlots,
  });
}

class NearbyFriendsResult {
  final UserLocation currentLocation;
  final List<ScheduleFriend> nearbyFriends;

  const NearbyFriendsResult({
    required this.currentLocation,
    required this.nearbyFriends,
  });
}

class ManageSchedule {
  final ScheduleRepository _repository;

  final AvailabilityService _availabilityService;

  final LocationRepository? _locationRepository;

  final DistanceService _distanceService;

  /// Friend is considered nearby within 2 km.
  static const double nearbyRadiusMeters = 2000;

  const ManageSchedule(
    this._repository,
    this._availabilityService, [
    this._locationRepository,
    this._distanceService = const DistanceService(),
  ]);

  Future<PlanningContext> validatePlanningSlot(PlanningContext context) async {
    final source = _repository;
    if (source is PlanningSlotValidator) {
      return (source as PlanningSlotValidator).validatePlanningSlot(context);
    }
    return context; // Explicit demo repositories have no server evidence.
  }

  Future<CreationComparison?> prepareProposalComparison(
      DateTime day, List<String> friendIds) async {
    if (friendIds.isEmpty) return null;
    final source = _repository;
    return source is ProposalComparisonProvider
        ? (source as ProposalComparisonProvider)
            .prepareProposalComparison(day, friendIds)
        : null;
  }

  // ===============================================================
  // FRIENDS
  // ===============================================================

  Future<List<ScheduleFriend>> loadFriends() {
    return _repository.getFriends();
  }

  // ===============================================================
  // NEARBY FRIENDS
  // ===============================================================

  bool get supportsLocation => _locationRepository != null;

  Future<NearbyFriendsResult> loadNearbyFriends({
    required List<ScheduleFriend> friends,
  }) async {
    // -------------------------------------------------------------
    // 1. Real GPS position from this phone
    // -------------------------------------------------------------

    final currentLocation = await _locationRepository!.getCurrentLocation();

    // -------------------------------------------------------------
    // 2. IDs of accepted friends
    // -------------------------------------------------------------

    final friendIds = friends
        .map(
          (friend) => friend.id,
        )
        .toList();

    // -------------------------------------------------------------
    // 3. Dummy/shared friend locations from Firebase
    // -------------------------------------------------------------

    final locations = await _repository.getFriendLocations(
      friendIds: friendIds,
    );

    // -------------------------------------------------------------
    // 4. Calculate distance
    // -------------------------------------------------------------

    final nearby = <ScheduleFriend>[];

    for (final friend in friends) {
      final friendLocation = locations[friend.id];

      if (friendLocation == null) {
        continue;
      }

      final distance = _distanceService.distanceMeters(
        currentLocation,
        friendLocation,
      );

      if (distance <= nearbyRadiusMeters) {
        nearby.add(
          friend.copyWith(
            distanceMeters: distance,
          ),
        );
      }
    }

    // -------------------------------------------------------------
    // 5. Closest first
    // -------------------------------------------------------------

    nearby.sort(
      (a, b) => (a.distanceMeters ?? double.infinity).compareTo(
        b.distanceMeters ?? double.infinity,
      ),
    );

    return NearbyFriendsResult(
      currentLocation: currentLocation,
      nearbyFriends: nearby,
    );
  }

  // ===============================================================
  // DAY
  // ===============================================================

  Future<ScheduleDayResult> loadDay({
    required DateTime day,
    required List<String> friendIds,
    required Duration duration,
  }) async {
    final myBlocks = await _repository.getMySchedule(
      day: day,
    );

    final friendBlocks = await _repository.getFriendsBusyBlocks(
      day: day,
      friendIds: friendIds,
    );

    final busyBlocks = <ScheduleBlock>[
      ...myBlocks,
      ...friendBlocks,
    ];

    final commonSlots = _availabilityService.findCommonSlots(
      day: day,
      busyBlocks: busyBlocks,
      duration: duration,
    );

    return ScheduleDayResult(
      myBlocks: myBlocks,
      friendBlocks: friendBlocks,
      commonSlots: commonSlots,
    );
  }
}
