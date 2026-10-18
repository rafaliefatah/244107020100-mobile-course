import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'messaging/push_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import 'data/api_client.dart';
import 'data/token_store.dart';
import 'data/auth_repository.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggedIn = authState.value ?? false;
      final goingLogin = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && !goingLogin) return AppRoutes.login;
      if (loggedIn && goingLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (_, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  registerBackgroundHandler();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final PushService _pushService;

  @override
  void initState() {
    super.initState();
    final router = ref.read(routerProvider);
    final dio = buildApiClient(TokenStore(), AuthRepository());
    _pushService = PushService(dio, (route) => router.go(route));
    unawaited(_initializePush());
  }

  Future<void> _initializePush() async {
    try {
      await _pushService.initialize();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'push service',
          context: ErrorDescription('Menginisialisasi push notification'),
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_pushService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Aplikasi Kampus',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
