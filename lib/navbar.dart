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

    return Container(
      color: Colors.transparent, // Ensure full transparency
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Navigation Bar Background
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white, // navbar stays white
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
                const SizedBox(width: 48), // space for the floating icon
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

          // Floating Search Button
          Positioned(
            bottom: 30,
            child: GestureDetector(
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  final hasAccepted =
                      doc.data()?['legalAiDisclaimerAccepted'] ?? false;

                  if (hasAccepted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LegalAi()),
                    );
                  } else {
                    _showLegalAiDisclaimerModal(context);
                  }
                }
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF580049),
                  border: Border.all(
                    color: const Color.fromARGB(255, 45, 0, 40),
                    width: 2,
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

void _showLegalAiDisclaimerModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elsa AI Legal Assistant',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Disclosure and Limitation of Liability',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'The Elsa AI Legal Assistant is a feature of the Philippine Electronic Legal Services and Access (PH-ELSA) application under the Integrated Bar of the Philippines (IBP). It provides users with general legal information, including jurisprudence, statutes, and fundamental legal principles. This feature utilizes artificial intelligence to generate responses based on publicly available legal data and user input. Please note that the information provided by Elsa AI is for informational purposes only and should not be considered as legal advice.\n\n'
            'By using this feature, you agree to the following terms:\n\n'
            '• No Legal Advice or Attorney-Client Relationship: This AI Assistant does not offer legal advice and does not create an attorney-client relationship. The responses are informational and should not be relied upon as a substitute for professional legal consultation.\n\n'
            '• Accuracy Not Guaranteed: While the AI aims to provide accurate and helpful information, it may not reflect the most recent legal developments or interpretations. Users are responsible for independently verifying all information.\n\n'
            '• Limitation of Liability: The IBP, its developers, and affiliated parties are not liable for any inaccuracies, omissions, or consequences arising from use of the AI Assistant. Use of this feature is entirely at your own risk.\n\n'
            '• User Responsibility: You are solely responsible for how you interpret and use the AI-generated content. Legal decisions should always be made with guidance from a licensed attorney.\n\n'
            '• Supplementary Tool Only: This feature is intended as a support tool for legal research and reference. It is not a replacement for formal legal services, education, or official legal sources.\n\n'
            'By continuing, you acknowledge that you have read, understood, and accepted this disclaimer and agree to hold harmless the IBP and all associated parties from any liability related to its use.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'I Understand',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'legalAiDisclaimerAccepted': true});
              }
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LegalAi()),
              );
            },
          ),
        ],
      );
    },
  );
}
