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

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggedIn = authState.value ?? false;
      final goingLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingLogin) return '/login';
      if (loggedIn && goingLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(
        path: '/pengumuman/:id',
        builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final granted = await requestNotificationPermission();
  if (granted) {
    await initLocalNotifications();
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  if (granted) {
    final store = TokenStore();
    final auth = AuthRepository();
    final dio = buildApiClient(store, auth);

    initFcmToken(onToken: (token) async {
      try {
        await dio.post('/devices', data: {
          'fcm_token': token,
          'platform': 'android',
        });
      } catch (_) {

      }
    });
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Aplikasi Kampus',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
