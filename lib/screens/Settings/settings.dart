import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ibp_app_ver2/screens/Settings/about.dart';
import 'package:ibp_app_ver2/screens/Settings/audit_logs.dart';
import 'package:ibp_app_ver2/screens/Settings/change_email_address.dart';
import 'package:ibp_app_ver2/screens/Settings/change_password.dart';
import 'package:ibp_app_ver2/screens/Settings/login_activity.dart';
import 'package:ibp_app_ver2/screens/Settings/terms_and_conditions.dart';
import 'package:ibp_app_ver2/screens/Settings/trusted_devices.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isGoogleLinked = false;
  bool _isTwoFactorEnabled = false;
  bool _isGoogleLinkLoading = false; // Separate loading state for Google link
  String _verificationId = ''; // To store the verification ID after sending OTP
  // ignore: unused_field
  bool _isPhoneVerificationInProgress =
      false; // To track the phone verification progress
  String? _phoneNumber; // To store the user's phone number

  @override
  void initState() {
    super.initState();
    _checkGoogleLink();
    _checkTwoFactorStatus();
  }

  bool _checkIfGoogleLinked(User user) {
    for (var provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return true;
      }
    }
    return false;
  }

  Future<void> _deactivateAccount() async {
    setState(() {});

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Update user_status to 'inactive' in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'user_status': 'inactive',
        });

        // Sign the user out after deactivation
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deactivated successfully.')),
        );

        // Navigate to login screen or any other screen after deactivation
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deactivate account: $e')),
      );
    } finally {
      setState(() {});
    }
  }

  Future<void> _checkTwoFactorStatus() async {
    setState(() {});

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _isTwoFactorEnabled = userDoc['isTwoFactorEnabled'] ?? false;
      });
    }

    setState(() {});
  }

  void _showOtpInputModal(BuildContext context) {
    TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'OTP',
              hintText: '123456',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final otp = otpController.text.trim();
                if (otp.isNotEmpty) {
                  final PhoneAuthCredential credential =
                      PhoneAuthProvider.credential(
                    verificationId: _verificationId,
                    smsCode: otp,
                  );
                  await _signInWithPhoneAuthCredential(credential);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithPhoneAuthCredential(
      PhoneAuthCredential credential) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.updatePhoneNumber(credential); // Link phone number

      // Enable 2FA in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'isTwoFactorEnabled': true});

      setState(() {
        _isTwoFactorEnabled = true;
        _isPhoneVerificationInProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Two-Factor Authentication enabled successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enable 2FA: $e')),
      );
      setState(() {
        _isPhoneVerificationInProgress = false;
      });
    }
  }

  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    setState(() {
      _isPhoneVerificationInProgress = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Automatically verify if possible
        await _signInWithPhoneAuthCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.message}')),
        );
        setState(() {
          _isPhoneVerificationInProgress = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
        // Show the OTP input dialog
        _showOtpInputModal(context);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  void _showPhoneNumberModal(BuildContext context) {
    TextEditingController phoneNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter your phone number'),
          content: TextField(
            controller: phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1234567890',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final phoneNumber = phoneNumberController.text.trim();
                if (phoneNumber.isNotEmpty) {
                  setState(() {
                    _phoneNumber = phoneNumber;
                  });
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({'phone': phoneNumber});

                  Navigator.of(context).pop();
                  await _verifyPhoneNumber(phoneNumber);
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleTwoFactorAuth(bool value) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (value) {
        // If enabling 2FA, check if the phone number exists
        if (_phoneNumber == null || _phoneNumber!.isEmpty) {
          _showPhoneNumberModal(context); // Show modal to add phone number
        } else {
          // Phone number exists, initiate phone number verification
          await _verifyPhoneNumber(_phoneNumber!);
        }
      } else {
        // Disabling 2FA, just update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'isTwoFactorEnabled': false});
        setState(() {
          _isTwoFactorEnabled = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Two-Factor Authentication disabled')),
        );
      }
    }
  }

  void _showDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF580049),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.emailVerified) {
      try {
        // Send the Firebase email verification link
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Verification email sent! Please check your inbox.')),
        );

        // Show a dialog explaining that they need to verify their email
        _sendVerificationEmail();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification email: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your email is already verified.')),
      );
    }
  }

  String _generateVerificationCode() {
    var rng = Random();
    return (rng.nextInt(900000) + 100000)
        .toString(); // Generates a random 6-digit code
  }

  Future<void> _checkGoogleLink() async {
    setState(() {});

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      for (var provider in user.providerData) {
        if (provider.providerId == 'google.com') {
          setState(() {
            _isGoogleLinked = true;
          });
          break;
        }
      }
    }

    setState(() {});
  }

  // Link the user's Google account
  Future<void> _linkGoogleAccount() async {
    setState(() {
      _isGoogleLinkLoading = true; // Set Google loading
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isGoogleLinkLoading = false; // Stop loading on cancel
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? user = FirebaseAuth.instance.currentUser;

      await user?.linkWithCredential(credential);

      setState(() {
        _isGoogleLinked = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google account linked successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to link Google account: $e')),
      );
    } finally {
      setState(() {
        _isGoogleLinkLoading = false; // Stop loading after operation
      });
    }
  }

  Future<void> _unlinkGoogleAccount() async {
    setState(() {
      _isGoogleLinkLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is signed in.')),
        );
        return;
      }

      await user.unlink('google.com');

      // Update Firestore to indicate Google account is unlinked
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isGoogleLinked': false});

      setState(() {
        _isGoogleLinked = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google account unlinked successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'requires-recent-login':
          message = 'Please re-authenticate and try again.';
          break;
        default:
          message = 'Failed to unlink Google account: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isGoogleLinkLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Settings'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Account Settings'),
          SettingTile(
            title: 'Change Email Address',
            icon: Icons.email,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const ChangeEmailAddressPage()),
              );
            },
          ),
          SettingTile(
            title: 'Change Password',
            icon: Icons.lock,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage()),
              );
            },
          ),
          SettingTile(
            title: _isGoogleLinked
                ? 'Unlink Google Account'
                : 'Connect Google Account',
            icon: Icons.account_circle,
            onTap: _isGoogleLinked ? _unlinkGoogleAccount : _linkGoogleAccount,
            trailing: _isGoogleLinkLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.arrow_forward_ios, color: Color(0xFF580049)),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Security'),
          SettingTile(
            title: 'Two-Factor Authentication (2FA)',
            icon: Icons.security,
            trailing: Switch(
              value: _isTwoFactorEnabled,
              onChanged: (bool value) {
                _toggleTwoFactorAuth(value);
              },
            ),
          ),
          SettingTile(
            title: 'Login Activity',
            icon: Icons.history,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const LoginActivityPage()),
              );
            },
          ),
          SettingTile(
            title: 'Trusted Devices',
            icon: Icons.device_hub,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const TrustedDevicesPage()),
              );
            },
          ),
          SettingTile(
            title: 'Audit Logs',
            icon: Icons.assignment, // Changed to assignment icon
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AuditLogPage(),
                ),
              );
            },
          ),
          SettingTile(
            title: 'Deactivate Account',
            icon: Icons.pause_circle_filled,
            onTap: () {
              _showConfirmationDialog(
                context,
                'Deactivate Account',
                'Are you sure you want to deactivate your account?',
                () {
                  Navigator.pop(context); // Close the dialog
                  _deactivateAccount(); // Call deactivate account function
                },
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'About & Support'),
          SettingTile(
            title: 'About',
            icon: Icons.info,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          SettingTile(
            title: 'Terms & Conditions and Privacy Policy',
            icon: Icons.article,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const TermsAndConditionsPage()),
              );
            },
          ),
          SettingTile(
            title: 'Contact Support',
            icon: Icons.support_agent,
            onTap: () {
              _showContactSupportModal(context);
            },
          ),
        ],
      ),
    );
  }

  void _showContactSupportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Development Team',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text('Email: nubcapstone@gmail.com'),
              Text('Phone: +63 929 301 0483'),
              SizedBox(height: 20),
              Text('Management Team',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text('Email: ibpbulacanchapter@gmail.com'),
              Text('Phone: +63 917 168 9873'),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF580049),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Confirmation Dialog for Deactivate and Delete Account
  void _showConfirmationDialog(BuildContext context, String title,
      String message, VoidCallback onConfirm) {
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          content: SizedBox(
            width: screenWidth * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Once deactivated, you will be signed out and will not be able to access your account until reactivated.',
                  style: TextStyle(fontSize: 14, color: Colors.redAccent),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF580049),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF580049),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onConfirm,
              child: const Text(
                'Deactivate',
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios, color: Color(0xFF580049)),
      onTap: onTap,
    );
  }
}
