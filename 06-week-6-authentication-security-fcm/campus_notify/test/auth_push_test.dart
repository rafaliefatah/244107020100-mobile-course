import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/notifications/route_from_message.dart';
import 'package:campus_notify/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:campus_notify/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/app/routes.dart';

void main() {
  test('routeFromMessage menangani route kosong dan tanpa slash', () {
    expect(routeFromMessage({}, fallbackRoute: AppRoutes.home), AppRoutes.home);
    expect(
      routeFromMessage({
        'route': 'pengumuman/3',
      }, fallbackRoute: AppRoutes.home),
      '/pengumuman/3',
    );
    expect(
      routeFromMessage({
        'route': '/pengumuman/3',
      }, fallbackRoute: AppRoutes.home),
      '/pengumuman/3',
    );
  });

  test('auth repository data implements domain contract', () {
    final AuthRepository repository = AuthRepositoryImpl(
      MockAuthRemoteDataSource(),
    );
    expect(repository, isA<AuthRepositoryImpl>());
  });

  test('sign in returns an auth session for valid credentials', () async {
    final repository = AuthRepositoryImpl(MockAuthRemoteDataSource());

    final result = await repository.signIn(
      email: 'student@campus.test',
      password: 'secure-password',
    );

    expect(result.failure, isNull);
    expect(result.session, isA<AuthSession>());
    expect(result.session!.access, contains('student@campus.test'));
    expect(result.session!.refresh, contains('student@campus.test'));
  });

  test('sign in returns a friendly failure for invalid credentials', () async {
    final repository = AuthRepositoryImpl(MockAuthRemoteDataSource());

    final result = await repository.signIn(
      email: 'invalid-email',
      password: 'short',
    );

    expect(result.session, isNull);
    expect(result.failure?.message, 'Email atau kata sandi tidak valid.');
  });
}
