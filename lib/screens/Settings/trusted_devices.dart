import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:http/http.dart' as http; // Correct import for HTTP requests

class TrustedDevicesPage extends StatefulWidget {
  const TrustedDevicesPage({super.key});

  @override
  _TrustedDevicesPageState createState() => _TrustedDevicesPageState();
}

class _TrustedDevicesPageState extends State<TrustedDevicesPage> {
  late User? user;
  bool _isLoading = true;
  List<Map<String, dynamic>> trustedDevices = [];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _fetchTrustedDevices();
  }

  Future<void> _fetchTrustedDevices() async {
    setState(() {
      _isLoading = true;
    });

    if (user != null) {
      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .collection('trusted_devices')
                .orderBy('last_login', descending: true)
                .get();

        List<Map<String, dynamic>> devices =
            snapshot.docs.map((doc) => doc.data()).toList();

        setState(() {
          trustedDevices = devices;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching trusted devices: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Function to format the last login time
  String _formatLastLoginTime(String lastLogin) {
    try {
      DateTime parsedDate = DateTime.parse(lastLogin);
      return DateFormat('EEE, MMM d, y h:mm a')
          .format(parsedDate); // e.g., "Mon, Aug 23, 2021 2:35 PM"
    } catch (e) {
      return lastLogin; // In case of error, return the raw string
    }
  }

  Future<void> _removeTrustedDevice(String deviceId) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('trusted_devices')
            .doc(deviceId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trusted device removed successfully.')),
        );

        _fetchTrustedDevices(); // Refresh the device list after removal
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing trusted device: $e')),
        );
      }
    }
  }

  Future<void> _logoutFromAllDevices() async {
    if (user != null) {
      try {
        // Get the Firebase ID token for authentication
        final token = await user!.getIdToken();

        // Make a POST request to the Cloud Function for logging out all devices
        final response = await http.post(
          Uri.parse(
              'https://us-central1-lawyer-app-ed056.cloudfunctions.net/logoutAllDevices'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'userId': user!.uid, // Pass the userId to the Cloud Function
          }),
        );

        if (response.statusCode == 200) {
          // Successfully logged out from all devices
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Logged out from all devices successfully.')),
          );

          // Clear the local session by signing out the current device
          await FirebaseAuth.instance.signOut();

          // After successful logout, redirect to login
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to log out from all devices.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out from all devices: $e')),
        );
      }
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
        title: const Text('Trusted Devices'),
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
          Padding(
            padding: const EdgeInsets.only(
                bottom: 60.0), // Leave space for the button
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : trustedDevices.isEmpty
                    ? const Center(
                        child: Text(
                          'No trusted devices found.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: trustedDevices.length,
                        itemBuilder: (context, index) {
                          final device = trustedDevices[index];
                          return _buildTrustedDeviceCard(device, screenWidth);
                        },
                      ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF580049),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _logoutFromAllDevices,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.exit_to_app,
                        color: Colors.white), // Add logout icon here
                    SizedBox(width: 10), // Space between the icon and text
                    Text(
                      'Logout from All Devices',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustedDeviceCard(
      Map<String, dynamic> device, double screenWidth) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 16), // Adding more horizontal margin
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 24), // Increased padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Device: ${device['device_name'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF580049),
                    ),
                  ),
                ),
                const Icon(Icons.device_hub, color: Color(0xFF580049)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'IP Address: ${device['ipAddress'] ?? 'Unknown'}',
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
                    'Location: ${device['location'] ?? 'Unknown'}',
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
                    'Platform: ${device['platform'] ?? 'Unknown'}',
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
                    'Last Login: ${_formatLastLoginTime(device['last_login'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phonelink_erase, color: Colors.red),
                  onPressed: () => _removeTrustedDevice(device['device_name']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
