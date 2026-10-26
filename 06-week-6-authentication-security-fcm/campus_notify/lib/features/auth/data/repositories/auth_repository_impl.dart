import '../../../../core/failures/failure.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<({AuthSession? session, Failure? failure})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return (
        session: await _remoteDataSource.signIn(
          email: email,
          password: password,
        ),
        failure: null,
      );
    } on AuthDataSourceException catch (error) {
      return (
        session: null,
        failure: AuthenticationFailure(error.message),
      );
    } catch (error) {
      return (session: null, failure: failureFromException(error));
    }
  }
}
