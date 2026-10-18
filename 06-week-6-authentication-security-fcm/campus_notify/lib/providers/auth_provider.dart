import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/api_errors.dart';
import '../data/token_store.dart';

// Inisialisasi instance langsung sesuai kode awal
final _tokenStore = TokenStore();
final _authRepository = AuthRepository();

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await _tokenStore.readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      await _tokenStore.save(access: session.access, refresh: session.refresh);
      state = const AsyncData(true);
    } catch (error, stackTrace) {
      final message = error is DioException
          ? apiErrorMessage(error)
          : error.toString().replaceFirst('Exception: ', '');
      state = AsyncError(message, stackTrace);
    }
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    ref.invalidateSelf();
  }
}
