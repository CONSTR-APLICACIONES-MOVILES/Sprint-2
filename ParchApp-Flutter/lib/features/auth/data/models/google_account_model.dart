import '../../domain/entities/google_account.dart';

class GoogleAccountModel {
  final String id;
  final String name;
  final String email;
  const GoogleAccountModel(
      {required this.id, required this.name, required this.email});

  GoogleAccount toEntity() => GoogleAccount(id: id, name: name, email: email);
}
