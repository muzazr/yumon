import '../../../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthApi {
  const AuthApi(this._client);

  final DioClient _client;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _parseAuthResponse(response.data);
    } catch (error) {
      throw _client.readableError(error);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final data = _unwrapData(response.data);
      return UserModel.fromJson(_userJson(data));
    } catch (error) {
      throw _client.readableError(error);
    }
  }

  Future<UserModel> me() async {
    try {
      final response = await _client.dio.get('/auth/me');
      final data = _unwrapData(response.data);
      return UserModel.fromJson(_userJson(data));
    } catch (error) {
      throw _client.readableError(error);
    }
  }

  AuthResult _parseAuthResponse(dynamic body) {
    final data = _unwrapData(body);
    final token = (data['accessToken'] ?? data['token'] ?? '').toString();
    final user = UserModel.fromJson(_userJson(data));

    if (token.isEmpty) {
      throw Exception('Login response does not include token.');
    }

    return AuthResult(token: token, user: user);
  }

  Map<String, dynamic> _unwrapData(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _userJson(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is Map<String, dynamic>) return user;
    return data;
  }
}
