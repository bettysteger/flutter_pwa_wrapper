import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:webview_flutter/webview_flutter.dart';


class PushNotificationsManager {
  static late PushNotificationsManager _instance;
  late FirebaseMessaging _firebaseMessaging;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  late WebViewController _webviewController;

  PushNotificationsManager._internal();

  static PushNotificationsManager getInstance() {
    _instance = PushNotificationsManager._internal();
    _instance._firebaseMessaging = FirebaseMessaging.instance;
    return _instance;
  }

  Future<bool> init(WebViewController webviewController, bool shouldAskForPushPermission) async {
    _webviewController = webviewController;
    if(_initialized) { return false; }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // _firebaseMessaging.getInitialMessage().then(_handleMessage);

    var bool = false;

    if(Platform.isAndroid) {
      bool = true;
      flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: onSelectNotification
      );
    }


    if (Platform.isIOS && !shouldAskForPushPermission) {
      bool = await requestPermission();
    }

    _initialized = bool;
    return bool;
  }

  Future<bool> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    debugPrint('handlePushNotification: ${message.data.toString()}');

    if (message.data['url'] != null) {
      return _webviewController.loadRequest(message.data['url']);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails('pwa_wrapper', 'PWA wrapper',
              importance: Importance.high,
              sound: RawResourceAndroidNotificationSound('notification')
            ),
          ),
          payload: jsonEncode(message.data)
      );
    }
  }

  void onSelectNotification(NotificationResponse? response) {
    String? payload = response?.payload;
    debugPrint('onSelectNotification: $payload');
    var data = jsonDecode(payload!);
    if(data['url'] != null) {
      _webviewController.loadRequest(data['url']);
    }
  }

  Future<String?> getToken() {
    return _firebaseMessaging.getToken();
  }

}
