import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ibp_app_ver2/screens/Appointments/appointments.dart';
import 'package:ibp_app_ver2/screens/Notifications/notifications.dart';
import 'package:ibp_app_ver2/screens/home.dart';
import 'package:ibp_app_ver2/screens/Profile/profile.dart';
import 'package:ibp_app_ver2/screens/LegalAi/legal_ai.dart';

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

    return SizedBox(
      height: 100, // enough height to show overlap above navbar
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
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
                const SizedBox(width: 48),
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
          ),

          // Floating circle icon
          Positioned(
            bottom: 30,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LegalAi()),
                );
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF580049),
                  border: Border.all(
                    color: const Color.fromARGB(255, 45, 0, 40),
                    width: 2, // adjust as needed for subtle or bold border
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
