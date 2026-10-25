import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/api_errors.dart';
import '../data/token_store.dart';

// Provider untuk TokenStore dan AuthRepository
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final tokenStore = ref.watch(tokenStoreProvider);
    final token = await tokenStore.readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final tokenStore = ref.read(tokenStoreProvider);

      final session = await authRepository.login(
        email: email,
        password: password,
      );
      await tokenStore.save(access: session.access, refresh: session.refresh);
      state = const AsyncData(true);
    } catch (error, stackTrace) {
      final message = error is DioException
          ? apiErrorMessage(error)
          : error.toString().replaceFirst('Exception: ', '');
      state = AsyncError(message, stackTrace);
    }
  }

  Future<void> logout() async {
    final tokenStore = ref.read(tokenStoreProvider);
    await tokenStore.clear();
    ref.invalidateSelf();
  }
}