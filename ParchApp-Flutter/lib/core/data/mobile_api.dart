import 'package:cloud_functions/cloud_functions.dart';

abstract interface class MobileApi {
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> input);
}

class FirebaseMobileApi implements MobileApi {
  final FirebaseFunctions functions;
  const FirebaseMobileApi(this.functions);
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    final result = await functions.httpsCallable(name).call(input);
    return Map<String, dynamic>.from(result.data as Map);
  }
}
