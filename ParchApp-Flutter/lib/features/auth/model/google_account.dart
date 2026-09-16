class GoogleAccount {
  final String id;
  final String name;
  final String email;

  const GoogleAccount({
    required this.id,
    required this.name,
    required this.email,
  });

  String get initials {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}