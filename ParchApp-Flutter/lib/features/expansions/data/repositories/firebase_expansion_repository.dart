import '../../../../core/data/mobile_api.dart';
import '../../domain/repositories/expansion_repository.dart';

class FirebaseExpansionRepository implements ExpansionRepository {
  final MobileApi api;
  final String? Function() currentUserId;
  const FirebaseExpansionRepository(this.api, this.currentUserId);
  @override
  String? get sessionId => currentUserId();
  @override
  Future<Map<String, dynamic>> request(
      String name, Map<String, dynamic> input) async {
    final uid = currentUserId();
    if (uid == null) throw StateError('Sign in to continue.');
    final result = await api.call(name, input);
    if (uid != currentUserId()) {
      throw StateError('Session changed. Reopen this screen.');
    }
    return result;
  }
}
