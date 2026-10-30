import '../entities/saved_credentials.dart';

abstract interface class SavedCredentialsRepository {
  Future<SavedCredentials?> read();
  Future<void> save(SavedCredentials credentials);
  Future<void> clear();
}