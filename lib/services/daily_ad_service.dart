import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app open count and one-time daily video ad access.
class DailyAdService {
  DailyAdService._internal();
  static final DailyAdService instance = DailyAdService._internal();

  static const String keyAppOpenCount = 'app_open_count';
  static const String keyLastDailyAdDate = 'last_daily_ad_date';
  static const int maxFreeOpens = 20;

  // Rewarded ad unit ID (consistent with About page)
  static const String rewardedAdUnitId =
      'ca-app-pub-6710120263757804/7307204400';

  /// Helper to get a date formatted as YYYY-MM-DD
  String getTodayDateString([DateTime? date]) {
    final now = date ?? DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Get current total app open count
  Future<int> getAppOpenCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(keyAppOpenCount) ?? 0;
    } catch (e) {
      debugPrint('DailyAdService: Error getting app open count: $e');
      return 0;
    }
  }

  /// Increment app open count by 1 and return the updated count.
  /// Called once per app launch session.
  Future<int> incrementAppOpenCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int count = prefs.getInt(keyAppOpenCount) ?? 0;
      count += 1;
      await prefs.setInt(keyAppOpenCount, count);
      debugPrint('DailyAdService: App open recorded. Count = $count');
      return count;
    } catch (e) {
      debugPrint('DailyAdService: Error incrementing app open count: $e');
      return 0;
    }
  }

  /// Checks if the user has already watched the daily video ad today.
  Future<bool> isDailyAdUnlockedForToday([DateTime? testDate]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(keyLastDailyAdDate);
      final today = getTodayDateString(testDate);
      return lastDate == today;
    } catch (e) {
      debugPrint('DailyAdService: Error checking daily ad status: $e');
      return false;
    }
  }

  /// Records that the user has completed watching the daily video ad today.
  Future<void> markDailyAdWatchedToday([DateTime? testDate]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = getTodayDateString(testDate);
      await prefs.setString(keyLastDailyAdDate, today);
      debugPrint('DailyAdService: Marked daily ad watched for $today');
    } catch (e) {
      debugPrint('DailyAdService: Error marking daily ad watched: $e');
    }
  }

  /// Determines if the user should be stopped before entering the app.
  ///
  /// Returns `true` ONLY if:
  /// - Not running on Web (where Google Mobile Ads is not used)
  /// - The app has been opened MORE than 20 times (`count > 20`)
  /// - The user has NOT watched the daily video ad today
  ///
  /// For the first 20 app opens, this always returns `false`.
  Future<bool> shouldGateAccess([DateTime? testDate]) async {
    if (kIsWeb) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(keyAppOpenCount) ?? 0;

      // For first 20 app opens: allow normal entry without any prompt or toast
      if (count <= maxFreeOpens) {
        return false;
      }

      // After 20 opens: check if already watched for the whole day
      final isUnlocked = await isDailyAdUnlockedForToday(testDate);
      if (isUnlocked) {
        return false; // Can use app whole day without watching again
      }

      // Must watch 1 video ad to unlock today's session
      return true;
    } catch (e) {
      debugPrint('DailyAdService: Error in shouldGateAccess: $e');
      return false;
    }
  }

  /// Reset preferences (useful for testing and debugging)
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyAppOpenCount);
    await prefs.remove(keyLastDailyAdDate);
  }

  /// Set arbitrary count (useful for testing)
  Future<void> setAppOpenCountForTesting(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyAppOpenCount, count);
  }
}
