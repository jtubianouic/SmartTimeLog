import 'package:flutter_test/flutter_test.dart';
import 'package:smarttimelog/services/smart_time_log_api.dart';

void main() {
  Map<String, dynamic> log(int id, String type, String time) => {
    'timelog_id': id,
    'employee_id': 42,
    'log_type': type,
    'timestamp': time,
  };

  test(
    'a new clock-in does not inherit a completed break from an older shift',
    () {
      final status = AttendanceStatus.fromJson({
        'status': 'clocked_in',
        'breakDurationSeconds': 300,
        'latestTimelog': log(5, 'clock_in', '2026-10-17T13:00:00Z'),
        'timelogs': [
          log(2, 'break_start', '2026-10-17T09:00:00Z'),
          log(4, 'clock_out', '2026-10-17T12:00:00Z'),
          log(5, 'clock_in', '2026-10-17T13:00:00Z'),
          log(3, 'break_end', '2026-10-17T09:05:00Z'),
          log(1, 'clock_in', '2026-10-17T08:00:00Z'),
        ],
      });

      expect(status.hasTakenBreak, isFalse);
    },
  );

  test('clock-in and clock-out records alone never complete a break', () {
    final status = AttendanceStatus.fromJson({
      'status': 'clocked_in',
      'timelogs': [
        log(3, 'clock_in', '2026-10-17T13:00:00Z'),
        log(2, 'clock_out', '2026-10-17T12:00:00Z'),
        log(1, 'clock_in', '2026-10-17T08:00:00Z'),
      ],
    });

    expect(status.hasTakenBreak, isFalse);
  });

  test(
    'a break end in the current shift completes the break even at zero seconds',
    () {
      final status = AttendanceStatus.fromJson({
        'status': 'clocked_in',
        'breakDurationSeconds': 0,
        'timelogs': [
          log(3, 'break_end', '2026-10-17T13:30:00Z'),
          log(2, 'break_start', '2026-10-17T13:30:00Z'),
          log(1, 'clock_in', '2026-10-17T13:00:00Z'),
        ],
      });

      expect(status.hasTakenBreak, isTrue);
    },
  );
}
