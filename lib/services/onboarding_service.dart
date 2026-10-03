import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingException implements Exception {
  const OnboardingException(this.message);

  final String message;
}

class OnboardingService {
  OnboardingService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static final OnboardingService instance = OnboardingService();
  static const _completedKey = 'onboarding_completed';
  static const _operationTimeout = Duration(seconds: 5);

  final FlutterSecureStorage _storage;

  Future<bool> shouldShow() async {
    try {
      final value = await _storage
          .read(key: _completedKey)
          .timeout(_operationTimeout);
      return value != 'true';
    } on Exception {
      throw const OnboardingException(
        'The saved introduction preference could not be read.',
      );
    }
  }

  Future<void> markCompleted() async {
    try {
      await _storage
          .write(key: _completedKey, value: 'true')
          .timeout(_operationTimeout);
    } on Exception {
      throw const OnboardingException(
        'The introduction preference could not be saved.',
      );
    }
  }
}
