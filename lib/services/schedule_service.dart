import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleService {
  static final ScheduleService instance = ScheduleService._init();

  static const String _keyEnabled = 'schedule_enabled';
  static const String _keyStartTime = 'schedule_start_time';
  static const String _keyEndTime = 'schedule_end_time';
  static const String _keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const String _keyQuietStart = 'quiet_start_time';
  static const String _keyQuietEnd = 'quiet_end_time';

  bool _scheduleEnabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0); // 10 PM
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);    // 6 AM

  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 23, minute: 0); // 11 PM
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);    // 7 AM

  ScheduleService._init();

  /// Load schedule settings from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _scheduleEnabled = prefs.getBool(_keyEnabled) ?? false;
    _quietHoursEnabled = prefs.getBool(_keyQuietHoursEnabled) ?? false;

    final startParts = (prefs.getString(_keyStartTime) ?? '22:00').split(':');
    _startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );

    final endParts = (prefs.getString(_keyEndTime) ?? '06:00').split(':');
    _endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    final quietStartParts = (prefs.getString(_keyQuietStart) ?? '23:00').split(':');
    _quietStart = TimeOfDay(
      hour: int.parse(quietStartParts[0]),
      minute: int.parse(quietStartParts[1]),
    );

    final quietEndParts = (prefs.getString(_keyQuietEnd) ?? '07:00').split(':');
    _quietEnd = TimeOfDay(
      hour: int.parse(quietEndParts[0]),
      minute: int.parse(quietEndParts[1]),
    );
  }

  /// Check if monitoring should be active right now based on schedule
  bool shouldMonitorNow() {
    if (!_scheduleEnabled) return true; // No schedule = always active

    final now = TimeOfDay.now();
    return _isTimeInRange(now, _startTime, _endTime);
  }

  /// Check if quiet hours are active (suppress notifications but keep monitoring)
  bool isQuietHoursNow() {
    if (!_quietHoursEnabled) return false;

    final now = TimeOfDay.now();
    return _isTimeInRange(now, _quietStart, _quietEnd);
  }

  /// Check if a time is within a range (supports overnight ranges like 22:00 - 06:00)
  bool _isTimeInRange(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Normal range (e.g., 09:00 - 17:00)
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Overnight range (e.g., 22:00 - 06:00)
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  /// Enable or disable schedule-based monitoring
  Future<void> setScheduleEnabled(bool value) async {
    _scheduleEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  /// Set monitoring start time
  Future<void> setStartTime(TimeOfDay time) async {
    _startTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStartTime, '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
  }

  /// Set monitoring end time
  Future<void> setEndTime(TimeOfDay time) async {
    _endTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEndTime, '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
  }

  /// Enable or disable quiet hours
  Future<void> setQuietHoursEnabled(bool value) async {
    _quietHoursEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyQuietHoursEnabled, value);
  }

  /// Set quiet hours start time
  Future<void> setQuietStart(TimeOfDay time) async {
    _quietStart = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuietStart, '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
  }

  /// Set quiet hours end time
  Future<void> setQuietEnd(TimeOfDay time) async {
    _quietEnd = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuietEnd, '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
  }

  // Getters
  bool get scheduleEnabled => _scheduleEnabled;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;
  bool get quietHoursEnabled => _quietHoursEnabled;
  TimeOfDay get quietStart => _quietStart;
  TimeOfDay get quietEnd => _quietEnd;

  /// Get schedule summary text
  String get scheduleSummary {
    if (!_scheduleEnabled) return 'Monitoring always active';
    return 'Monitoring: ${_formatTime(_startTime)} - ${_formatTime(_endTime)}';
  }

  /// Get quiet hours summary text
  String get quietHoursSummary {
    if (!_quietHoursEnabled) return 'Quiet hours disabled';
    return 'Quiet: ${_formatTime(_quietStart)} - ${_formatTime(_quietEnd)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get all settings as JSON map
  Map<String, dynamic> toJson() {
    return {
      'scheduleEnabled': _scheduleEnabled,
      'startTime': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      'quietHoursEnabled': _quietHoursEnabled,
      'quietStart': '${_quietStart.hour.toString().padLeft(2, '0')}:${_quietStart.minute.toString().padLeft(2, '0')}',
      'quietEnd': '${_quietEnd.hour.toString().padLeft(2, '0')}:${_quietEnd.minute.toString().padLeft(2, '0')}',
    };
  }

  /// Load settings from JSON map
  Future<void> fromJson(Map<String, dynamic> json) async {
    if (json['scheduleEnabled'] != null) {
      await setScheduleEnabled(json['scheduleEnabled'] as bool);
    }
    if (json['startTime'] != null) {
      final parts = (json['startTime'] as String).split(':');
      await setStartTime(TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    }
    if (json['endTime'] != null) {
      final parts = (json['endTime'] as String).split(':');
      await setEndTime(TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    }
    if (json['quietHoursEnabled'] != null) {
      await setQuietHoursEnabled(json['quietHoursEnabled'] as bool);
    }
    if (json['quietStart'] != null) {
      final parts = (json['quietStart'] as String).split(':');
      await setQuietStart(TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    }
    if (json['quietEnd'] != null) {
      final parts = (json['quietEnd'] as String).split(':');
      await setQuietEnd(TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    }
  }
}
