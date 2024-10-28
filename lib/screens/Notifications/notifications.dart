import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:ibp_app_ver2/navbar.dart';
import 'package:ibp_app_ver2/screens/Appointments/appointmentDetails.dart';
import 'package:intl/intl.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key, required int activeIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Stack(
        children: [
          const NotificationsList(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const CustomNavigationBar(
                activeIndex: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsList extends StatefulWidget {
  const NotificationsList({super.key});

  @override
  _NotificationsListState createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _initializeRemoteConfig();
    _listenForNotifications();
  }

  Future<void> _initializeRemoteConfig() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await _remoteConfig.setDefaults(<String, dynamic>{
      'notification_color': 'blue',
      'default_notification_message': 'You have a new notification!',
    });

    await _fetchRemoteConfig();
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Failed to fetch remote config: $e');
    }
  }

  String get notificationColor => _remoteConfig.getString('notification_color');
  String get defaultNotificationMessage =>
      _remoteConfig.getString('default_notification_message');

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;

      FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final notificationData = change.doc.data();
            _showFlutterNotification(notificationData!);
            change.doc.reference.update({'read': true});
          }
        }
      });
    }
  }

  void _showFlutterNotification(Map<String, dynamic> notificationData) async {
    String type = notificationData['type'] ?? 'general';
    String message = notificationData['message'] ?? defaultNotificationMessage;
    String title;
    IconData icon;

    // Customize title and icon based on notification type
    switch (type) {
      case 'appointment':
        title = 'New Appointment';
        icon = Icons.calendar_today;
        message = 'You have an upcoming appointment!';
        break;
      case 'profile_update':
        title = 'Profile Updated';
        icon = Icons.edit;
        message = 'Your profile was successfully updated!';
        break;
      case 'reminder':
        title = 'Reminder';
        icon = Icons.alarm;
        message = 'You have a scheduled reminder.';
        break;
      default:
        title = 'Notification';
        icon = Icons.notifications;
        break;
    }

    // Customize notification appearance and behavior based on type
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'ibp_notifications', // Channel ID
      'IBP Notifications', // Channel name
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation:
          BigTextStyleInformation(''), // Allows for larger messages
      icon: '@mipmap/ic_launcher', // Custom icon based on type
      color: Colors.blue,
    );

    // Notification details for each platform
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show the customized notification popup
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      message,
      platformChannelSpecifics,
      payload: notificationData['controlNumber'], // Payload for additional data
    );
  }

  Future<void> _markAllAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;
      final notificationsRef =
          FirebaseFirestore.instance.collection('notifications');

      final unreadNotificationsSnapshot = await notificationsRef
          .where('uid', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadNotificationsSnapshot.docs) {
        await doc.reference.update({'read': true});
      }
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('No user'));

    final userId = currentUser.uid;
    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final timestamp = notification['timestamp'] as Timestamp?;
              final type = notification['type'] ?? '';
              final message =
                  notification['message'] ?? defaultNotificationMessage;
              final isRead = notification['read'] ?? false;
              final controlNumber = notification['controlNumber'] ?? '';

              IconData icon;
              switch (type) {
                case 'appointment':
                  icon = Icons.calendar_today;
                  break;
                case 'profile_update':
                  icon = Icons.edit;
                  break;
                default:
                  icon = Icons.mail;
              }

              Color notificationBgColor = isRead
                  ? Colors.white
                  : (notificationColor == 'blue'
                      ? Colors.blue[50]!
                      : Colors.grey[50]!);

              return InkWell(
                onTap: () {
                  if (controlNumber.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetails(
                          controlNumber: controlNumber,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    color: notificationBgColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isRead
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                    border: Border.all(
                      color: isRead ? Colors.grey[300]! : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(icon,
                            color: const Color(0xFF580049), size: 28),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              message,
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.visible,
                            ),
                            const SizedBox(height: 4),
                            if (timestamp != null)
                              Text(
                                DateFormat('MMMM dd, yyyy \'at\' hh:mm a')
                                    .format(timestamp.toDate()),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        const Icon(Icons.circle, color: Colors.red, size: 12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _markAllAsRead();
    super.dispose();
  }
}
