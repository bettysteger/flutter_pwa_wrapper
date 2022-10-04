import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push/push.dart';
import 'package:webview_flutter/webview_flutter.dart';


class PushNotificationsManager {
  static late PushNotificationsManager _instance;
  late Push _push;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  late WebViewController _webviewController;

  PushNotificationsManager._internal();

  static PushNotificationsManager getInstance() {
    _instance = PushNotificationsManager._internal();
    _instance._push = Push.instance;
    return _instance;
  }

  Future<bool> init(WebViewController webviewController, bool shouldAskForPushPermission) async {
    _webviewController = webviewController;
    if(_initialized) { return false; }

    Push.instance.onNotificationTap.listen(_handleMessage);
    Push.instance.onMessage.listen(_handleForegroundMessage);
    // _push.getInitialMessage().then(_handleMessage);

    var bool = false;

    if(Platform.isAndroid) {
      bool = true;
      flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: IOSInitializationSettings()
        ),
        onSelectNotification: onSelectNotification
      );
    }


    if (Platform.isIOS && !shouldAskForPushPermission) {
      bool = await requestPermission();
    }

    _initialized = bool;
    return bool;
  }

  Future<bool> requestPermission() async {
    bool granted = await _push.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return granted;
  }

  Future<void> _handleMessage(message) async {
    debugPrint('handlePushNotification: ${message.toString()}');
    String? url = message['payload'] != null ? jsonDecode(message['payload'])['url'] : message['url'];

    if (url != null) {
      return _webviewController.loadUrl(url);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('handleForegroundMessage: ${message.toString()}');
    var notification = message.notification;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(),
          payload: jsonEncode(message.data)
      );
    }
  }

  Future onSelectNotification(String? payload) {
    debugPrint('onSelectNotification: $payload');
    var data = jsonDecode(payload!);
    if(data['url'] != null) {
      return _webviewController.loadUrl(data['url']);
    }
    return Future.value();
  }

  Future<String?> getToken() {
    return _push.token;
  }

}
