import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../core/notifications/push_service.dart';
import 'router.dart';

final pushServiceProvider = Provider.family<PushService, void Function(String)>(
  (ref, navigate) {
    final service = PushService(ref.watch(dioProvider), navigate);
    ref.onDispose(() => unawaited(service.dispose()));
    return service;
  },
);

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  late final PushService _pushService;

  @override
  void initState() {
    super.initState();
    final router = ref.read(routerProvider);
    _pushService = ref.read(pushServiceProvider((route) => router.go(route)));
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
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aplikasi Kampus',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
