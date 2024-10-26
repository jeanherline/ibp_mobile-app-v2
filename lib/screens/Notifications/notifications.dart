import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                activeIndex: 2, // Ensure this shows the active home tab
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
  final List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    // Fetch initial notifications in real-time via Stream
  }

  @override
  void dispose() {
    // Mark all notifications as read when the user exits the page
    _markAllAsRead();
    super.dispose();
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
              final message = notification['message'] ?? 'No message available';
              final isRead = notification['read'] ?? false;
              final controlNumber = notification['controlNumber'] ??
                  ''; // Ensure controlNumber is present

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

              return InkWell(
                onTap: () {
                  // Navigate to AppointmentDetails and pass the control number
                  if (controlNumber.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetails(
                          controlNumber: controlNumber,
                        ),
                      ),
                    );
                  } else {
                    print('Error: Control number is missing.');
                  }
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : Colors.blue[50],
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
                        child: Icon(
                          icon,
                          color: const Color(0xFF580049),
                          size: 28,
                        ),
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
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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
}
