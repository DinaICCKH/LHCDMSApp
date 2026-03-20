class SessionManager {
  static DateTime? lastActivity;

  // Update when user interacts
  static void updateActivity() {
    lastActivity = DateTime.now();
  }

  // Check timeout (10 minutes)
  static bool isExpired() {
    if (lastActivity == null) return false;

    final diff = DateTime.now().difference(lastActivity!);
    return diff.inMinutes >= 10;
  }
}