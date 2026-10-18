import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes.dart';

const _announcementTopic = 'pengumuman-kampus';
const _androidChannelId = 'pengumuman';
const _androidChannelName = 'Pengumuman Kampus';
const _androidChannelDescription = 'Notifikasi pengumuman kampus';
const _androidChannel = AndroidNotificationChannel(
  _androidChannelId,
  _androidChannelName,
  description: _androidChannelDescription,
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handler berjalan di isolate terpisah. Jangan akses BuildContext atau Riverpod.
  await Firebase.initializeApp();
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

class PushService {
  PushService(
    this._dio,
    this._navigate, {
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final Dio _dio;
  final void Function(String route) _navigate;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  bool _initialized = false;
  bool _permissionGranted = false;

  Future<bool> initialize() async {
    if (_initialized) {
      if (_permissionGranted) return true;
      _permissionGranted = await requestPermission();
      if (_permissionGranted) await _registerForPush();
      return _permissionGranted;
    }

    await _initializeLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
      onError: (Object error, StackTrace stackTrace) =>
          _reportError('Menerima push notification', error, stackTrace),
    );
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openMessageRoute,
      onError: (Object error, StackTrace stackTrace) =>
          _reportError('Membuka push notification', error, stackTrace),
    );
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) => unawaited(_registerTokenAndReport(token)),
      onError: (Object error, StackTrace stackTrace) =>
          _reportError('Memperbarui token FCM', error, stackTrace),
    );

    _initialized = true;
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _openMessageRoute(initialMessage);

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final launchRoute = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchRoute != null &&
        launchRoute.isNotEmpty) {
      _navigate(launchRoute);
    }

    _permissionGranted = await requestPermission();
    if (_permissionGranted) await _registerForPush();
    return _permissionGranted;
  }

  Future<void> _registerForPush() async {
    await subscribeToAnnouncements();
    final token = await getToken();
    if (token != null) await _registerToken(token);
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<bool> requestPermission() async {
    // Android 13+ meminta POST_NOTIFICATIONS saat runtime; panggilan FCM ini
    // memicu dialog tersebut. iOS menampilkan prompt izin alert/badge/sound.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> subscribeToAnnouncements() =>
      _messaging.subscribeToTopic(_announcementTopic);

  Future<void> unsubscribeFromAnnouncements() =>
      _messaging.unsubscribeFromTopic(_announcementTopic);

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) _navigate(route);
      },
    );

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(_androidChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _localNotifications.show(
        id: message.hashCode & 0x7fffffff,
        title: message.notification?.title ?? 'Pengumuman',
        body: message.notification?.body ?? '',
        notificationDetails: notificationDetails,
        payload: routeFromMessage(message.data),
      );
    } catch (error, stackTrace) {
      _reportError('Menampilkan notifikasi lokal', error, stackTrace);
    }
  }

  Future<void> _registerToken(String token) async {
    final platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
        ? 'android'
        : throw UnsupportedError('Push notification hanya didukung mobile');
    await _dio.post<void>(
      '/devices',
      data: {'fcm_token': token, 'platform': platform},
    );
  }

  Future<void> _registerTokenAndReport(String token) async {
    try {
      await _registerToken(token);
    } catch (error, stackTrace) {
      _reportError('Mengirim token FCM ke /devices', error, stackTrace);
    }
  }

  void _openMessageRoute(RemoteMessage message) {
    _navigate(routeFromMessage(message.data));
  }

  void _reportError(String context, Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'push service',
        context: ErrorDescription(context),
      ),
    );
  }
}
