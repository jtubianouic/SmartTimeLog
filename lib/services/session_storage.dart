import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> deleteAll();
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const Duration _operationTimeout = Duration(seconds: 5);

  @override
  Future<String?> read(String key) =>
      _storage.read(key: key).timeout(_operationTimeout);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value).timeout(_operationTimeout);

  @override
  Future<void> deleteAll() => _storage.deleteAll().timeout(_operationTimeout);
}
