import '../repositories/calendar_import_repository.dart';

class AuthorizeGoogleCalendar {
  final CalendarImportRepository repository;

  const AuthorizeGoogleCalendar(
    this.repository,
  );

  Future<void> call() {
    return repository.authorizeCalendar();
  }
}