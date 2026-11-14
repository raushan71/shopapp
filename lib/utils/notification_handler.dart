import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ready_ecommerce/firebase_options.dart';

// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   await setupFlutterNotifications();
//   showFlutterNotification(message);
//   debugPrint('Handling a background message ${message.messageId}');
// }

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await setupFlutterNotifications();
  // Notification payloads are displayed by Android/iOS while the app is in
  // the background. Data-only payloads need a local notification.
  if (message.notification == null) {
    await showFlutterNotification(message);
  }

  debugPrint('Background message: ${message.messageId}');
}

Future<void> firebaseMessagingForgroundHandler() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  FirebaseMessaging.onMessage.listen((message) async {
    debugPrint('Handling a ForeGround message ${message.messageId}');
    await showFlutterNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  handleMessage(await FirebaseMessaging.instance.getInitialMessage());

  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    debugPrint('FCM token refreshed: $token');
  });
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true);

  const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@drawable/notification_icon'),
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveBackgroundNotificationResponse: onDidReceiveLocalNotification,
    onDidReceiveNotificationResponse: onSelectNotification,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

Future<void> showFlutterNotification(RemoteMessage message) async {
  if (kIsWeb) return;
  if (defaultTargetPlatform == TargetPlatform.iOS &&
      message.notification != null) {
    return;
  }

  final notification = message.notification;
  final title = notification?.title ?? message.data['title']?.toString();
  final body = notification?.body ?? message.data['body']?.toString();
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    debugPrint('Notification ignored because it has no title or body.');
    return;
  }

  await flutterLocalNotificationsPlugin.show(
    message.messageId?.hashCode ?? message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: '@drawable/notification_icon',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.isEmpty ? null : jsonEncode(message.data),
  );
}

// handle notification navigation
void handleMessage(RemoteMessage? message) {
  if (message == null) return;
  if (message.data['type'] == 'Conversetion') {
    // call the context less route here
  }
}

// Background notification selection
Future<void> onDidReceiveLocalNotification(
  NotificationResponse notificationResponse,
) async {
  // ContextLess.navigatorkey.currentState!.pushNamedAndRemoveUntil(
  //   Routes.messageScreen,
  //   arguments: MessageScreenArgument(
  //     orderId: orderId,
  //     senderId: receiverId,
  //     receiverId: senderId,
  //   ),
  //   (route) => true,
  // );
}

// Foreground notification selection
Future<void> onSelectNotification(
  NotificationResponse notificationResponse,
) async {
  // ContextLess.navigatorkey.currentState!.pushNamedAndRemoveUntil(
  //   Routes.messageScreen,
  //   arguments: MessageScreenArgument(
  //     orderId: orderId,
  //     senderId: receiverId,
  //     receiverId: senderId,
  //   ),
  //   (route) => true,
  // );
}

// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
