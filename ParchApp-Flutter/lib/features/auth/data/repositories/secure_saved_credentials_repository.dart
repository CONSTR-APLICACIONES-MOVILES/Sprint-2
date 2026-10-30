import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/saved_credentials.dart';
import '../../domain/repositories/saved_credentials_repository.dart';

class SecureSavedCredentialsRepository implements SavedCredentialsRepository {
  static const _emailKey = 'face_id_sign_in.email';
  static const _passwordKey = 'face_id_sign_in.password';
  final FlutterSecureStorage _storage;

  const SecureSavedCredentialsRepository(
      [this._storage = const FlutterSecureStorage()]);

  @override
  Future<SavedCredentials?> read() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      if (email == null || password == null) return null;
      return SavedCredentials(email: email, password: password);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(SavedCredentials credentials) async {
    await _storage.write(key: _emailKey, value: credentials.email);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}