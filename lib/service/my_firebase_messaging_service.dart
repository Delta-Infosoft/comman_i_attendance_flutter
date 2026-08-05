import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class MyFirebaseMessagingService {
  static final plugin = FlutterLocalNotificationsPlugin();

  static const channel = AndroidNotificationChannel(
      "high_importance_channel", "High Importance Notifications",
      description: "Desc of Notification",
      playSound: true,
      importance: Importance.high);

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    WidgetsFlutterBinding.ensureInitialized();
    print("A Background Message was received: ${message.messageId}");
  }

  static Future<void> backgroundMessage() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (Platform.isAndroid) {
      await plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!
          .createNotificationChannel(channel);
      print("This is Android");
    } else if (Platform.isIOS) {
      print("This is IOS");
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
  }

  static Future<void> initilizeNotification() async {
    if (Platform.isAndroid) {
      var initializationSettingsAndroid =
      const AndroidInitializationSettings('@mipmap/ic_launcher');

      var initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      plugin.initialize(initializationSettings);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? androidNotification =
            message.notification?.android;

        if (notification != null && androidNotification != null) {
          // Use BigTextStyle to show multiple lines in the notification
          plugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                playSound: true,
                icon: '@mipmap/ic_launcher',
                color: Colors.blue,
                styleInformation: BigTextStyleInformation(
                  notification.body ?? '',
                  htmlFormatBigText: true,
                  contentTitle: notification.title ?? '',
                  htmlFormatContent: true,
                ),
              ),
            ),
          );
        }
      });
    } else if (Platform.isIOS) {
      // iOS-specific initialization settings
      var initializationSettingsIOS = const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      var initializationSettings = InitializationSettings(
        iOS: initializationSettingsIOS,
      );

      plugin.initialize(initializationSettings);

      // Request iOS notification permissions
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      print("This is iOS");
    }
  }

  static Future<void> showNotification(
      {required String title, required String body}) async {
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'high_importance_channel', // Channel ID
        'High Importance Notifications', // Channel Name
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        title, // Notification Title
        body, // Notification Body
        platformChannelSpecifics,
      );
    } catch (e) {
      print("Error showing notification: $e");
    }
  }
}
