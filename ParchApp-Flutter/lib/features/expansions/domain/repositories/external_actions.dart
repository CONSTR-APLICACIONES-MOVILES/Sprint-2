abstract interface class ExternalActions {
  String? enrollmentUrl(String token);
  Future<void> copy(String text);
  Future<String> shareText(String text);
  Future<String> shareCalendar(String fileName, String content);
  Future<bool> openResource(String url);
}
