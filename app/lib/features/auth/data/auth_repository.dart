import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import 'auth_api.dart';

class AuthRepository {
  const AuthRepository(this._api, this._storage);

  static const _useFakeAuth = bool.fromEnvironment(
    'YUMON_FAKE_AUTH',
    defaultValue: true,
  );
  static const _fakeUser = UserModel(
    id: 'fake-user',
    name: 'Yumon Tester',
    email: 'tester@yumon.local',
  );
  static const _fakeToken = 'fake-dev-token';

  final AuthApi _api;
  final SecureStorageService _storage;

  Future<UserModel?> loadCurrentUser() async {
    if (_useFakeAuth) {
      await _saveSession(const AuthResult(token: _fakeToken, user: _fakeUser));
      return _fakeUser;
    }

    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;

    final storedName = await _storage.readUserName();
    final storedEmail = await _storage.readUserEmail();
    if (storedName != null && storedEmail != null) {
      return UserModel(id: '', name: storedName, email: storedEmail);
    }

    final user = await _api.me();
    await _storage.saveUser(name: user.name, email: user.email);
    return user;
  }

  Future<UserModel> login(String email, String password) async {
    if (_useFakeAuth) {
      final user = UserModel(
        id: _fakeUser.id,
        name: _fakeUser.name,
        email: email.isEmpty ? _fakeUser.email : email,
      );
      await _saveSession(AuthResult(token: _fakeToken, user: user));
      return user;
    }

    final result = await _api.login(email: email, password: password);
    await _saveSession(result);
    return result.user;
  }

  Future<UserModel> register(String name, String email, String password) async {
    if (_useFakeAuth) {
      final user = UserModel(
        id: _fakeUser.id,
        name: name.isEmpty ? _fakeUser.name : name,
        email: email.isEmpty ? _fakeUser.email : email,
      );
      await _saveSession(AuthResult(token: _fakeToken, user: user));
      return user;
    }

    final result = await _api.register(
      name: name,
      email: email,
      password: password,
    );
    await _saveSession(result);
    return result.user;
  }

  Future<void> logout() => _storage.clearSession();

  Future<void> _saveSession(AuthResult result) async {
    await _storage.saveToken(result.token);
    await _storage.saveUser(name: result.user.name, email: result.user.email);
  }
}
