import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';

// Inisialisasi instance langsung sesuai kode awal
final _tokenStore = TokenStore();
final _authRepository = AuthRepository();

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await _tokenStore.readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      await _tokenStore.save(
        access: session.access,
        refresh: session.refresh,
      );
      return true;
    });
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    ref.invalidateSelf();
  }
}