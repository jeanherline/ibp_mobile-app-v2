import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ibp_app_ver2/screens/Appointments/appointments.dart';
import 'package:ibp_app_ver2/screens/Notifications/notifications.dart';
import 'package:ibp_app_ver2/screens/home.dart';
import 'package:ibp_app_ver2/screens/Profile/profile.dart';

class CustomNavigationBar extends StatefulWidget {
  final int activeIndex; // Accept activeIndex from parent screen

  const CustomNavigationBar({super.key, required this.activeIndex});

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox
          .shrink(); // Return an empty widget if no user is logged in
    }

    final userId = currentUser.uid;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: widget.activeIndex == 0
                  ? const Color.fromARGB(255, 79, 134, 216)
                  : const Color(0xFF580049),
            ),
            onPressed: () {
              if (widget.activeIndex != 0) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const Home(activeIndex: 0),
                  ),
                );
              }
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.calendar_month,
                  color: widget.activeIndex == 1
                      ? const Color.fromARGB(255, 79, 134, 216)
                      : const Color(0xFF580049),
                ),
                onPressed: () {
                  if (widget.activeIndex != 1) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            const Appointments(activeIndex: 1),
                      ),
                    );
                  }
                },
              ),
              // Stream for unread appointments
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('applicantProfile.uid', isEqualTo: userId)
                    .where('appointmentDetails.read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final unreadAppointmentsCount = snapshot.data!.docs.length;

                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadAppointmentsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications,
                  color: widget.activeIndex == 2
                      ? const Color.fromARGB(255, 79, 134, 216)
                      : const Color(0xFF580049),
                ),
                onPressed: () {
                  if (widget.activeIndex != 2) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            const Notifications(activeIndex: 2),
                      ),
                    );
                  }
                },
              ),
              // Stream for unread notifications
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('uid', isEqualTo: userId)
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final unreadCount = snapshot.data!.docs.length;

                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              color: widget.activeIndex == 3
                  ? const Color.fromARGB(255, 79, 134, 216)
                  : const Color(0xFF580049),
            ),
            onPressed: () {
              if (widget.activeIndex != 3) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const Profile(activeIndex: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
