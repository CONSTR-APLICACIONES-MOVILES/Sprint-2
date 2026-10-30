class QuickStatus {
  final String freeUntil, nextActivity;
  const QuickStatus({this.freeUntil = '', this.nextActivity = ''});
  QuickStatus update(String free, String next) => QuickStatus(
      freeUntil: free.trim().isEmpty ? freeUntil : free.trim(),
      nextActivity: next.trim().isEmpty ? nextActivity : next.trim());
}
