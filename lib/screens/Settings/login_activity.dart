import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class LoginActivityPage extends StatefulWidget {
  const LoginActivityPage({super.key});

  @override
  _LoginActivityPageState createState() => _LoginActivityPageState();
}

class _LoginActivityPageState extends State<LoginActivityPage> {
  late User? user;
  bool _isLoading = true;
  List<Map<String, dynamic>> loginActivities = [];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _fetchLoginActivities();
  }

  Future<void> _fetchLoginActivities() async {
    setState(() {
      _isLoading = true;
    });

    if (user != null) {
      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .collection('loginActivity')
                .orderBy('loginTime', descending: true)
                .get();

        List<Map<String, dynamic>> activities =
            snapshot.docs.map((doc) => doc.data()).toList();

        setState(() {
          loginActivities = activities;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching login activities: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Function to format the login time
  String _formatLoginTime(String loginTime) {
    try {
      DateTime parsedDate = DateTime.parse(loginTime);
      return DateFormat('EEE, MMM d, y h:mm a')
          .format(parsedDate); // e.g., "Mon, Aug 23, 2021 2:35 PM"
    } catch (e) {
      return loginTime; // In case of error, return the raw string
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Login Activity'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : loginActivities.isEmpty
                ? const Center(
                    child: Text(
                      'No login activity found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: loginActivities.length,
                    itemBuilder: (context, index) {
                      final activity = loginActivities[index];
                      return _buildLoginActivityCard(activity, screenWidth);
                    },
                  ),
      ),
    );
  }

  Widget _buildLoginActivityCard(
      Map<String, dynamic> activity, double screenWidth) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Device: ${activity['deviceName'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF580049),
                    ),
                  ),
                ),
                const Icon(Icons.smartphone, color: Color(0xFF580049)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'IP Address: ${activity['ipAddress'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Location: ${activity['location'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Login Time: ${_formatLoginTime(activity['loginTime'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
