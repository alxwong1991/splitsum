import 'account.dart';

class AuthResult {
  const AuthResult(this.token, this.expiresIn, this.account);
  final String token;
  final int expiresIn;
  final Account account;
}
