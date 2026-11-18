import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paletteasian/services/daily_ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyAdService Tests', () {
    test('Initial app open count is 0 and gating is false', () async {
      final service = DailyAdService.instance;
      await service.resetForTesting();

      final count = await service.getAppOpenCount();
      expect(count, equals(0));

      final shouldGate = await service.shouldGateAccess();
      expect(shouldGate, isFalse);
    });

    test('First 20 app opens do not gate the user (normal use)', () async {
      final service = DailyAdService.instance;
      await service.resetForTesting();

      for (int i = 1; i <= 20; i++) {
        final count = await service.incrementAppOpenCount();
        expect(count, equals(i));

        final shouldGate = await service.shouldGateAccess();
        expect(
          shouldGate,
          isFalse,
          reason: 'App open $i (<= 20) should not gate the user',
        );
      }
    });

    test('On 21st app open, user is gated if ad has not been watched today',
        () async {
      final service = DailyAdService.instance;
      await service.resetForTesting();
      await service.setAppOpenCountForTesting(20);

      // 21st open
      final count = await service.incrementAppOpenCount();
      expect(count, equals(21));

      // Not watched today
      final isUnlocked = await service.isDailyAdUnlockedForToday();
      expect(isUnlocked, isFalse);

      final shouldGate = await service.shouldGateAccess();
      expect(
        shouldGate,
        isTrue,
        reason: '21st open (> 20) with ad not watched today must gate user',
      );
    });

    test('Watching video ad unlocks access for the whole day', () async {
      final service = DailyAdService.instance;
      await service.resetForTesting();
      await service.setAppOpenCountForTesting(21);

      // Before watching
      expect(await service.shouldGateAccess(), isTrue);

      // Watch video ad today
      await service.markDailyAdWatchedToday();

      // After watching
      expect(await service.isDailyAdUnlockedForToday(), isTrue);
      expect(
        await service.shouldGateAccess(),
        isFalse,
        reason:
            'Once watched, user can use the app the whole day without watching again',
      );

      // Subsequent app opens on the same day remain unlocked
      await service.incrementAppOpenCount(); // 22
      expect(await service.shouldGateAccess(), isFalse);

      await service.incrementAppOpenCount(); // 23
      expect(await service.shouldGateAccess(), isFalse);
    });

    test('New day requires watching a video ad again', () async {
      final service = DailyAdService.instance;
      await service.resetForTesting();
      await service.setAppOpenCountForTesting(25);

      final day1 = DateTime(2026, 11, 18);
      final day2 = DateTime(2026, 11, 19);

      // Watch ad on Day 1
      await service.markDailyAdWatchedToday(day1);
      expect(await service.isDailyAdUnlockedForToday(day1), isTrue);
      expect(await service.shouldGateAccess(day1), isFalse);

      // On Day 2, Day 1 unlock does not apply
      expect(await service.isDailyAdUnlockedForToday(day2), isFalse);
      expect(
        await service.shouldGateAccess(day2),
        isTrue,
        reason: 'On a new day, user must watch the single daily ad again',
      );

      // Watch ad on Day 2
      await service.markDailyAdWatchedToday(day2);
      expect(await service.isDailyAdUnlockedForToday(day2), isTrue);
      expect(await service.shouldGateAccess(day2), isFalse);
    });
  });
}
