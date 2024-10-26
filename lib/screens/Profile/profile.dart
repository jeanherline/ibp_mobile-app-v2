import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ibp_app_ver2/navbar.dart';
import 'package:ibp_app_ver2/qr_code_scanner_screen.dart';
import 'package:ibp_app_ver2/screens/Profile/edit_profile.dart';
import 'package:ibp_app_ver2/screens/Settings/settings.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, required int activeIndex});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<Profile> {
  String _displayName = '';
  String _email = '';
  String _city = '';
  String _memberType = '';
  String _photoUrl = '';
  String _userQrCode = '';

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  Future<void> _fetchUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? '';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context)
          .pushReplacementNamed('/login'); // Navigate back to the login screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  void _showQrCodeModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(
              16.0), // Added more padding for better spacing
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _userQrCode.isNotEmpty
                          ? Image.network(_userQrCode)
                          : const Text('No QR code available.'),
                    ),
                    const SizedBox(
                        height:
                            20), // Increased space between the QR code and the text
                    const Text(
                      'This is your personal QR code.', // First line bold
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(
                            255, 0, 0, 0), // Lighter color for a softer tone
                        fontWeight: FontWeight.bold, // Bold for emphasis
                      ),
                    ),
                    const SizedBox(height: 5), // Space between two lines
                    const Text(
                      'Show this to the front desk when you walk into the IBP office.', // Second line
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5A5A5A), // Same lighter color
                        fontStyle: FontStyle.italic, // Italic style
                        fontWeight:
                            FontWeight.w400, // Light weight for soft tone
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfileImage(String newPhotoUrl) async {
    setState(() {
      _photoUrl = newPhotoUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
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
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;

              if (data != null) {
                _photoUrl = data['photo_url'] ?? '';
                String firstName = data['display_name'] ?? '';
                String middleName = data['middle_name'] ?? '';
                String lastName = data['last_name'] ?? '';
                _displayName = '$firstName $middleName $lastName';
                _city = data['city'] ?? '';
                _memberType = data['member_type'] ?? '';
                _userQrCode = data['userQrCode'];
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: CircleAvatar(
                    radius: screenWidth * 0.2,
                    backgroundImage: _photoUrl.isNotEmpty
                        ? NetworkImage(_photoUrl)
                        : const AssetImage('assets/img/DefaultUserImage.jpg')
                            as ImageProvider,
                    backgroundColor: Colors.grey[200],
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.verified,
                            color: Colors.blue[600],
                            size: 28), // Or Icons.check_circle
                      ),
                    ),
                  ),
                ),
                Text(
                  _displayName,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _email,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: screenWidth * 0.045,
                    color: const Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _city,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: screenWidth * 0.045,
                    color: const Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    children: [
                      if (_memberType == 'frontdesk')
                        _buildProfileButton(
                          label: 'Front Desk QR Scanner',
                          icon: Icons.qr_code_scanner,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const QRCodeScannerScreen()),
                            );
                          },
                        ),
                      _buildProfileButton(
                        label: 'Edit Profile',
                        icon: Icons.edit,
                        onPressed: () async {
                          final newPhotoUrl = await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const EditProfile()),
                          );
                          if (newPhotoUrl != null) {
                            _updateProfileImage(newPhotoUrl);
                          }
                        },
                      ),
                      _buildProfileButton(
                        label: 'Personal QR Code',
                        icon: Icons.qr_code_2_rounded,
                        onPressed: () {
                          _showQrCodeModal(context);
                        },
                      ),
                      _buildProfileButton(
                        label: 'Settings',
                        icon: Icons.settings,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()),
                          );
                        },
                      ),
                      _buildProfileButton(
                        label: 'Logout',
                        icon: Icons.logout,
                        onPressed: () async {
                          await _signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(
        activeIndex: 3,
      ),
    );
  }

  Widget _buildProfileButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
          backgroundColor: Colors.white,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: screenWidth * 0.06, color: Colors.black),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: screenWidth * 0.045,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
