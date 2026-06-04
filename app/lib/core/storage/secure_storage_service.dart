import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'yumon_token';
  static const _userNameKey = 'yumon_user_name';
  static const _userEmailKey = 'yumon_user_email';
  static const _lastSyncKey = 'yumon_last_sync_at';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> saveUser({required String name, required String email}) async {
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userEmailKey, value: email);
  }

  Future<String?> readUserName() => _storage.read(key: _userNameKey);
  Future<String?> readUserEmail() => _storage.read(key: _userEmailKey);

  Future<void> saveLastSyncAt(DateTime date) =>
      _storage.write(key: _lastSyncKey, value: date.toIso8601String());

  Future<DateTime?> readLastSyncAt() async {
    final value = await _storage.read(key: _lastSyncKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
  }
}
