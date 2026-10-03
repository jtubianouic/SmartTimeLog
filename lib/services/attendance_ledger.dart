import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AttendanceEventType {
  clockIn,
  breakStart,
  breakEnd,
  clockOut;

  String get label => switch (this) {
    clockIn => 'Clocked in',
    breakStart => 'Break started',
    breakEnd => 'Break ended',
    clockOut => 'Clocked out',
  };

  factory AttendanceEventType.fromJson(String value) => switch (value) {
    'clockIn' => clockIn,
    'breakStart' => breakStart,
    'breakEnd' => breakEnd,
    'clockOut' => clockOut,
    _ => throw const FormatException('Invalid attendance event type.'),
  };
}

class AttendanceLedgerEvent {
  const AttendanceLedgerEvent({
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  final AttendanceEventType type;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  factory AttendanceLedgerEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '');
    if (type is! String || timestamp == null) {
      throw const FormatException('Invalid attendance ledger event.');
    }
    return AttendanceLedgerEvent(
      type: AttendanceEventType.fromJson(type),
      timestamp: timestamp,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };
}

class AttendanceLedgerException implements Exception {
  const AttendanceLedgerException(this.message);

  final String message;
}

class AttendanceLedger {
  AttendanceLedger({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static final AttendanceLedger instance = AttendanceLedger();
  static const _storageKey = 'attendance_ledger';
  static const _operationTimeout = Duration(seconds: 5);

  final FlutterSecureStorage _storage;

  Future<List<AttendanceLedgerEvent>> load() async {
    final String? value;
    try {
      value = await _storage
          .read(key: _storageKey)
          .timeout(_operationTimeout);
    } on Exception {
      throw const AttendanceLedgerException(
        'Attendance history is unavailable on this device.',
      );
    }
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List<dynamic>) {
        throw const FormatException('Invalid attendance ledger.');
      }
      final events = decoded.map((entry) {
        if (entry is! Map) {
          throw const FormatException('Invalid attendance ledger event.');
        }
        return AttendanceLedgerEvent.fromJson(
          Map<String, dynamic>.from(entry),
        );
      }).toList();
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return events;
    } on FormatException {
      throw const AttendanceLedgerException(
        'Your saved attendance history could not be read.',
      );
    }
  }

  Future<void> record({
    required AttendanceEventType type,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
  }) async {
    final events = await load();
    final updated = [
      AttendanceLedgerEvent(
        type: type,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
      ),
      ...events,
    ].take(200).toList();
    try {
      await _storage
          .write(
            key: _storageKey,
            value: jsonEncode(updated.map((event) => event.toJson()).toList()),
          )
          .timeout(_operationTimeout);
    } on Exception {
      throw const AttendanceLedgerException(
        'The attendance action succeeded, but local history was not saved.',
      );
    }
  }
}
