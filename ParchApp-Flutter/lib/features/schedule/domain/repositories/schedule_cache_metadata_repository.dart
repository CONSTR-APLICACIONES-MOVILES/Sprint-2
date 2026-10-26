abstract interface class
    ScheduleCacheMetadataRepository {
  Future<DateTime?> getLastUpdated(
    DateTime day,
  );

  Future<void> markUpdated(
    DateTime day,
    DateTime updatedAt,
  );
}