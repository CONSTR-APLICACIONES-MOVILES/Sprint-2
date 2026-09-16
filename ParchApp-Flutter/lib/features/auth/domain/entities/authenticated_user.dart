class AuthenticatedUser {
  final String id;
  final String name;
  final String program;
  final String email;
  final bool verified;

  const AuthenticatedUser({
    required this.id,
    required this.name,
    required this.program,
    required this.email,
    required this.verified,
  });

  String get firstName {
    final parts = name.trim().split(' ');

    if (parts.isEmpty) {
      return name;
    }

    return parts.first;
  }

  String get initials {
    final parts =
        name.trim().split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
