import '../../domain/entities/auth_session.dart';

class AuthDataSourceException implements Exception {
  const AuthDataSourceException(this.message);

  final String message;
}

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> signIn({
    required String email,
    required String password,
  });
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@') || password.length < 6) {
      throw const AuthDataSourceException(
        'Email atau kata sandi tidak valid.',
      );
    }

    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }
}
