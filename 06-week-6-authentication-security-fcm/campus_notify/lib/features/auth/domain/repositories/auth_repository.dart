import '../../../../core/failures/failure.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<({AuthSession? session, Failure? failure})> signIn({
    required String email,
    required String password,
  });
}
