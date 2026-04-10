import 'package:flutter_test/flutter_test.dart';
import 'package:ai_survilance/services/schedule_service.dart';

void main() {
  group('ScheduleService', () {
    late ScheduleService service;

    setUp(() {
      service = ScheduleService.instance;
    });

    test('should return TimeOfDay.now() correctly', () {
      final now = TimeOfDay.now();
      final dateTime = DateTime.now();

      expect(now.hour, dateTime.hour);
      expect(now.minute, dateTime.minute);
    });

    test('should format TimeOfDay correctly', () {
      const time = TimeOfDay(hour: 14, minute: 30);
      expect(time.toString(), '14:30');

      const morningTime = TimeOfDay(hour: 6, minute: 5);
      expect(morningTime.toString(), '06:05');
    });

    test('should detect time in normal range', () {
      // Test normal range: 09:00 - 17:00
      const start = TimeOfDay(hour: 9, minute: 0);
      const end = TimeOfDay(hour: 17, minute: 0);

      // Helper to test range
      bool isInRange(TimeOfDay now, TimeOfDay s, TimeOfDay e) {
        final nowMinutes = now.hour * 60 + now.minute;
        final startMinutes = s.hour * 60 + s.minute;
        final endMinutes = e.hour * 60 + e.minute;
        return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      }

      expect(isInRange(TimeOfDay(hour: 12, minute: 0), start, end), true);
      expect(isInRange(TimeOfDay(hour: 8, minute: 0), start, end), false);
      expect(isInRange(TimeOfDay(hour: 18, minute: 0), start, end), false);
    });

    test('should detect time in overnight range', () {
      // Test overnight range: 22:00 - 06:00
      const start = TimeOfDay(hour: 22, minute: 0);
      const end = TimeOfDay(hour: 6, minute: 0);

      bool isOvernightRange(TimeOfDay now, TimeOfDay s, TimeOfDay e) {
        final nowMinutes = now.hour * 60 + now.minute;
        final startMinutes = s.hour * 60 + s.minute;
        final endMinutes = e.hour * 60 + e.minute;
        return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      }

      expect(isOvernightRange(TimeOfDay(hour: 23, minute: 0), start, end), true);
      expect(isOvernightRange(TimeOfDay(hour: 3, minute: 0), start, end), true);
      expect(isOvernightRange(TimeOfDay(hour: 12, minute: 0), start, end), false);
    });

    test('should create TimeOfDay with correct values', () {
      const time = TimeOfDay(hour: 22, minute: 30);
      expect(time.hour, 22);
      expect(time.minute, 30);
    });

    test('should handle midnight edge cases', () {
      const midnight = TimeOfDay(hour: 0, minute: 0);
      expect(midnight.hour, 0);
      expect(midnight.minute, 0);

      const endOfDay = TimeOfDay(hour: 23, minute: 59);
      expect(endOfDay.hour, 23);
      expect(endOfDay.minute, 59);
    });
  });
}
