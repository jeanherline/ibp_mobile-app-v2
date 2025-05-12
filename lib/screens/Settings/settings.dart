import 'dart:async';

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
  bool _is2FALoading = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleLink();
    _checkTwoFactorStatus();
    _loadUserPhoneNumber(); // ✅ Add this line
  }

  Future<void> _loadUserPhoneNumber() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final phone = userDoc['phone'];
      if (phone != null && phone.toString().isNotEmpty) {
        setState(() {
          _phoneNumber = phone;
        });
      }
    }
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
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;
    bool isTrusted = false;
    int countdown = 120;
    Timer? timer;

    void startCountdown(Function setModalState) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (countdown > 0) {
          setModalState(() => countdown--);
        } else {
          t.cancel();
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF580049)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Two-Factor Authentication',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF580049),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: screenWidth * 0.85,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter the 6-digit code sent to your registered mobile number to complete verification.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: '123456',
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF580049), width: 2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isTrusted,
                          onChanged: (val) {
                            setModalState(() => isTrusted = val ?? false);
                          },
                        ),
                        const Expanded(child: Text('Trust this device')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      countdown > 0
                          ? 'Resend code in 0:${countdown.toString().padLeft(2, '0')}'
                          : 'Didn’t get the code?',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    if (countdown == 0)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _verifyPhoneNumber(_phoneNumber!);
                        },
                        child: const Text('Resend Code'),
                      ),
                    if (isVerifying) const SizedBox(height: 16),
                    if (isVerifying)
                      const CircularProgressIndicator(strokeWidth: 2),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 10),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification cancelled.')),
                    );
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton.icon(
                  icon: isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_user_outlined,
                          size: 18, color: Colors.white),
                  label: const Text(
                    'Verify',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF580049),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          if (otp.isNotEmpty) {
                            setModalState(() => isVerifying = true);
                            final credential = PhoneAuthProvider.credential(
                              verificationId: _verificationId,
                              smsCode: otp,
                            );
                            await _signInWithPhoneAuthCredential(credential);
                            timer?.cancel();
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter the OTP code.')),
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    ).then((_) => timer?.cancel());

    startCountdown((fn) => {});
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

  String _formatPhoneNumber(String rawPhone) {
    rawPhone = rawPhone.trim();
    if (rawPhone.startsWith('+')) return rawPhone;
    if (rawPhone.startsWith('0')) return '+63${rawPhone.substring(1)}';
    if (rawPhone.startsWith('9')) return '+63$rawPhone';
    return rawPhone; // fallback
  }

  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    setState(() {
      _isPhoneVerificationInProgress = true;
    });

    final formattedPhone = _formatPhoneNumber(phoneNumber);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedPhone,
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
    TextEditingController phoneNumberController =
        TextEditingController(text: _phoneNumber ?? '');

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
      setState(() {
        _is2FALoading = true;
      });

      try {
        if (value) {
          // If enabling 2FA and phone number is missing, prompt first
          if (_phoneNumber == null || _phoneNumber!.isEmpty) {
            _showPhoneNumberModal(context);
          } else {
            // Phone number exists, initiate verification
            await _verifyPhoneNumber(_phoneNumber!);
          }
        } else {
          // Disabling 2FA
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('2FA toggle failed: $e')),
        );
      } finally {
        setState(() {
          _is2FALoading = false;
        });
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
          const SizedBox(height: 24),
          const SectionHeader(title: 'Security'),
          SettingTile(
            title: 'Two-Factor Authentication (2FA)',
            icon: Icons.security,
            trailing: _is2FALoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
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
