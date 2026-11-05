import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/account.dart';
import '../models/auth_result.dart';

class AuthApi {
  AuthApi({required this.client});
  final ApiClient client;

  Future<AuthResult> authenticate({
    required bool register,
    required String email,
    required String password,
  }) async {
    final Object? response;
    try {
      response = await client.request(
        'POST',
        register ? '/auth/register' : '/auth/login',
        body: {'email': email.trim().toLowerCase(), 'password': password},
      );
    } on ApiException catch (failure) {
      if (!register && failure.status == 401) {
        throw const ApiException('Invalid email or password.', status: 401);
      }
      if (failure.status == 409) {
        throw const ApiException(
          'Unable to register with these details. Try signing in.',
          status: 409,
        );
      }
      rethrow;
    }
    try {
      if (response is! Map<String, dynamic> ||
          response['accessToken'] is! String ||
          (response['accessToken'] as String).isEmpty ||
          response['tokenType'] != 'Bearer' ||
          response['expiresIn'] is! int ||
          (response['expiresIn'] as int) <= 0) {
        throw const FormatException('Invalid authentication response.');
      }
      return AuthResult(
        response['accessToken'] as String,
        response['expiresIn'] as int,
        Account.fromJson(response['user']),
      );
    } on FormatException {
      throw const ApiException(
        'The backend returned an invalid account response.',
      );
    }
  }

  Future<Account> me(String token) async =>
      _account(await client.request('GET', '/users/me', token: token));

  Future<Account> updateName(String token, String name) async => _account(
    await client.request(
      'PATCH',
      '/users/me',
      token: token,
      body: {'displayName': name.trim()},
    ),
  );

  Account _account(Object? response) {
    try {
      return Account.fromJson(response);
    } on FormatException {
      throw const ApiException(
        'The backend returned an invalid account response.',
      );
    }
  }

  void close() => client.close();
}
