import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error_mapper.dart';
import '../../data/data_sources/auth_remote_data_source.dart';
import '../../data/data_sources/token_local_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/sign_in.dart';

final tokenLocalDataSourceProvider = Provider<TokenLocalDataSource>(
  (ref) => TokenLocalDataSource(),
);
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => MockAuthRemoteDataSource(),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);
final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final authControllerProvider = AsyncNotifierProvider<AuthController, bool>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      return await ref.watch(tokenLocalDataSourceProvider).readAccess() != null;
    } catch (error, stackTrace) {
      final failure = failureFromException(error);
      Error.throwWithStackTrace(failure.message, stackTrace);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref.read(signInProvider).call(
      email: email,
      password: password,
    );
    final failure = result.failure;
    final session = result.session;
    if (failure != null || session == null) {
      state = AsyncError(
        failure?.message ?? 'Login gagal. Silakan coba lagi.',
        StackTrace.current,
      );
      return;
    }

    try {
      await ref.read(tokenLocalDataSourceProvider).save(
        access: session.access,
        refresh: session.refresh,
      );
      state = const AsyncData(true);
    } catch (error, stackTrace) {
      final failure = failureFromException(error);
      state = AsyncError(failure.message, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await ref.read(tokenLocalDataSourceProvider).clear();
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      final failure = failureFromException(error);
      state = AsyncError(failure.message, stackTrace);
    }
  }
}
