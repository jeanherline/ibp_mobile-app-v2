import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:ibp_app_ver2/screens/home.dart';
import 'package:ibp_app_ver2/screens/signup.dart';
import 'package:google_sign_in/google_sign_in.dart'; // For Google sign-in
import 'package:shared_preferences/shared_preferences.dart'; // For storing session

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  String? currentVerificationId;
  int? currentResendToken;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? userId = prefs.getString('userId');

    if (token != null && userId != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        bool isActive = await checkUserStatus(userId);
        if (isActive) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const Home(
                      activeIndex: 1,
                    )),
          );
        } else {
          _showDialog('Sign In Failed', 'Your account is not active.');
        }
      }
    }
  }

  void _showFacebookModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
            'The Facebook Sign-In feature is currently under construction.\n\nPlease try again later or use Google Sign-In.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _logAuditEntry(
      User? user, String actionType, String status) async {
    String userId = user?.uid ?? 'Unknown User';
    String userName = user?.displayName ?? 'Unknown';

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    String userAgent =
        'Android ${androidInfo.version.release}, Device: ${androidInfo.model}';

    String ipAddress = 'Unknown IP';
    String location = 'Unknown Location';

    try {
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=text'));
      if (response.statusCode == 200) {
        ipAddress = response.body;

        final locationResponse =
            await http.get(Uri.parse('http://ip-api.com/json/$ipAddress'));
        if (locationResponse.statusCode == 200) {
          final locationData = locationResponse.body;
          final decodedLocationData = jsonDecode(locationData);
          location =
              "${decodedLocationData['city']}, ${decodedLocationData['regionName']}, ${decodedLocationData['country']}";
        }
      }
    } catch (e) {
      print('Failed to fetch IP address or location: $e');
    }

    final timestamp = FieldValue.serverTimestamp();

    final auditLog = {
      'actionType': actionType,
      'affectedData': {
        'userId': userId,
        'userName': userName,
      },
      'changes': {
        'action': 'Login',
        'status': status,
      },
      'metadata': {
        'ipAddress': ipAddress,
        'location': location,
        'userAgent': userAgent,
      },
      'timestamp': timestamp,
      'uid': userId,
    };

    try {
      await FirebaseFirestore.instance.collection('audit_logs').add(auditLog);
    } catch (e) {
      print('Failed to write audit log: $e');
    }
  }

  Future<bool> _showInactiveModal(String userEmail) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              title: const Row(
                children: [
                  Icon(Icons.block, color: Color(0xFF580049)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Account Inactive',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF580049),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: screenWidth * 0.8,
                child: const Text(
                  'Your account is currently inactive. If you believe this is a mistake or would like to request reactivation, we can send a message to admin@ph-elsa.com on your behalf.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF580049),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF580049),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Send Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _sendReactivationEmail(
    String userEmail,
    String displayName,
    String middleName,
    String lastName,
    String uid,
  ) async {
    final url = Uri.parse('https://formspree.io/f/mjkwprrw');
    final payload = {
      'name': '$displayName $middleName $lastName',
      'email': userEmail,
      'message': 'A user has requested to reactivate their account.\n\n'
          'Name: $displayName $middleName $lastName\n'
          'Email: $userEmail\n'
          'UID: $uid',
      '_subject': 'Account Reactivation Request',
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Reactivation request sent successfully');
      } else {
        print(
            '❌ Failed to send request: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending reactivation email: $e');
    }
  }

  Future<void> _continueStandardLogin(User user) async {
    if (user.emailVerified) {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      final userData = userDoc.data();
      final userStatus = userData?['user_status'] ?? 'inactive';
      final isTwoFactorEnabled = userData?['isTwoFactorEnabled'] ?? false;

      // If deactivated, block and ask for reactivation
      if (userStatus == 'deactivated') {
        bool request = await _showInactiveModal(user.email ?? '');
        if (request) {
          final displayName = userData?['display_name'] ?? '';
          final middleName = userData?['middle_name'] ?? '';
          final lastName = userData?['last_name'] ?? '';

          await _sendReactivationEmail(
            user.email ?? '',
            displayName,
            middleName,
            lastName,
            user.uid,
          );

          await _showRequestSentDialog();
        }

        await FirebaseAuth.instance.signOut();
        await _logAuditEntry(user, 'ACCESS', 'Blocked: Deactivated account');
        return;
      }

      // If inactive, check if 2FA is enabled
      if (userStatus == 'inactive' && isTwoFactorEnabled) {
        bool verified = await _trigger2FAPhoneVerification(user);
        if (!verified) {
          await FirebaseAuth.instance.signOut();
          await _logAuditEntry(user, 'ACCESS', '2FA Failed: Inactive status');
          return;
        }
      }

      // If active OR passed 2FA (or inactive but 2FA is off)
      await _logLoginActivityAndTrustedDevice(user);
      await _logAuditEntry(user, 'ACCESS', 'Success');

      final token = await user.getIdToken();
      if (token != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        await prefs.setString('userId', user.uid);
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Home(activeIndex: 1)),
      );
    } else {
      _showDialog(
          'Email Not Verified', 'Please verify your email before logging in.');
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<bool> _trigger2FAPhoneVerification(User user) async {
    final auth = FirebaseAuth.instance;
    final phoneNumber = user.phoneNumber;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showDialog('Error', 'No phone number registered in Firebase Auth.');
      return false;
    }

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final deviceName = androidInfo.model ?? 'Unknown device';

    // Check if this device is trusted
    final trustedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trusted_devices')
        .doc(deviceName)
        .get();

    if (trustedDoc.exists) {
      return true; // just return true, don't re-enter _continueStandardLogin
    }

    bool isVerified = false;

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          User? signedInUser = userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code != 'provider-already-linked') {
            _showDialog(
                'Verification Failed', e.message ?? 'An error occurred.');
            return;
          }
        }

        Navigator.of(context).pop(); // Close OTP dialog if open
      },
      verificationFailed: (FirebaseAuthException e) {
        _showDialog('Verification Failed', e.message ?? 'An error occurred.');
      },
      codeSent: (String verificationId, int? resendToken) async {
        currentVerificationId = verificationId;
        currentResendToken = resendToken;
        isVerified =
            await _showOTPVerificationDialog(verificationId, user, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return isVerified;
  }

  Future<bool> _showOTPVerificationDialog(
    String verificationId,
    User user,
    int? resendToken,
  ) async {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;
    bool isTrusted = false;
    int countdown = 120;
    late Timer timer;
    bool timerStarted = false;
    String currentVerificationId = verificationId;

    void startTimer(VoidCallback refresh) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (countdown > 0) {
          countdown--;
          refresh();
        } else {
          t.cancel();
        }
      });
    }

    final bool isSuccess = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                if (!timerStarted) {
                  timerStarted = true;
                  startTimer(() => setModalState(() {}));
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter the 6-digit code sent to your phone.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'OTP Code',
                          counterText: '',
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 10),
                      countdown > 0
                          ? Text(
                              'Resend code in 0:${countdown.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            )
                          : TextButton(
                              onPressed: () async {
                                setModalState(() {
                                  countdown = 120;
                                });
                                FirebaseAuth.instance.verifyPhoneNumber(
                                  phoneNumber: user.phoneNumber!,
                                  forceResendingToken: resendToken,
                                  verificationCompleted:
                                      (PhoneAuthCredential credential) async {
                                    try {
                                      UserCredential userCredential =
                                          await FirebaseAuth.instance
                                              .signInWithCredential(credential);
                                      User? signedInUser = userCredential.user;

                                      if (signedInUser != null) {
                                        await _logLoginActivityAndTrustedDevice(
                                            signedInUser,
                                            addToTrusted: isTrusted);
                                        await _continueStandardLogin(
                                            signedInUser);
                                        Navigator.of(context).pop(true);
                                      } else {
                                        _showDialog('Verification Failed',
                                            'No user found after verification.');
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      if (e.code != 'provider-already-linked') {
                                        _showDialog('Verification Failed',
                                            e.message ?? 'An error occurred.');
                                        return;
                                      }
                                    }

                                    await _logLoginActivityAndTrustedDevice(
                                        user,
                                        addToTrusted: isTrusted);
                                    Navigator.of(context).pop(true);
                                  },
                                  verificationFailed:
                                      (FirebaseAuthException e) {
                                    _showDialog('Verification Failed',
                                        e.message ?? 'An error occurred.');
                                  },
                                  codeSent: (String newVerificationId,
                                      int? newResendToken) async {
                                    currentVerificationId = newVerificationId;
                                    resendToken = newResendToken;
                                  },
                                  codeAutoRetrievalTimeout:
                                      (String verificationId) {},
                                );
                              },
                              child: const Text(
                                'Didn’t get the code? Resend',
                                style:
                                    TextStyle(fontSize: 13, color: Colors.blue),
                              ),
                            )
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        timer.cancel();
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF580049),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isVerifying
                          ? null
                          : () async {
                              setModalState(() => isVerifying = true);
                              try {
                                final credential = PhoneAuthProvider.credential(
                                  verificationId: currentVerificationId,
                                  smsCode: otpController.text.trim(),
                                );

                                try {
                                  UserCredential userCredential =
                                      await FirebaseAuth.instance
                                          .signInWithCredential(credential);
                                  User? signedInUser = userCredential.user;

                                  if (signedInUser != null) {
                                    await _logLoginActivityAndTrustedDevice(
                                        signedInUser,
                                        addToTrusted: isTrusted);
                                    await _continueStandardLogin(signedInUser);
                                    Navigator.of(context).pop(true);
                                  } else {
                                    _showDialog('Verification Failed',
                                        'No user found after verification.');
                                  }
                                } on FirebaseAuthException catch (e) {
                                  if (e.code != 'provider-already-linked') {
                                    _showDialog('Verification Failed',
                                        e.message ?? 'An error occurred.');
                                    return;
                                  }
                                }
                                Navigator.of(context).pop(true);
                              } catch (e) {
                                _showDialog(
                                    'Verification Failed', e.toString());
                              } finally {
                                setModalState(() => isVerifying = false);
                                timer.cancel();
                              }
                            },
                      child: const Text('Verify'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    return isSuccess;
  }

  Future<void> _showRequestSentDialog() async {
    final screenWidth = MediaQuery.of(context).size.width;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
        title: Row(
          children: const [
            Icon(Icons.mark_email_read_rounded, color: Color(0xFF580049)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Request Sent',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF580049),
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: screenWidth * 0.8,
          child: const Text(
            'Your reactivation request has been successfully sent to admin@ph-elsa.com. Please wait for confirmation before attempting to log in again.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF580049),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        // Check if 2FA is enabled for the user in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        bool isTwoFactorEnabled =
            userDoc.data()?['isTwoFactorEnabled'] ?? false;

        // Check if there is any login activity
        final loginActivityQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('loginActivity')
            .get();

        bool hasLoginActivity = loginActivityQuery.docs.isNotEmpty;

        // If no login activity, skip 2FA for the first login
        if (isTwoFactorEnabled) {
          bool verified = await _trigger2FAPhoneVerification(user);
          if (!verified) {
            await FirebaseAuth.instance.signOut();
            return; // 🔁 prevent continuing if 2FA failed
          }
        }
        await _continueStandardLogin(
            user); // ✅ only if 2FA passed or not required
      }
    } on FirebaseAuthException catch (e) {
      String title = 'Sign In Failed';
      String message = 'An unknown error occurred.';

      switch (e.code) {
        case 'user-not-found':
          title = 'Email Not Found';
          message = 'No user found for that email.';
          await _logAuditEntry(null, 'user_not_found', 'Failed');
          break;
        case 'wrong-password':
          title = 'Incorrect Password';
          message = 'Wrong password provided.';
          await _logAuditEntry(null, 'wrong_password', 'Failed');
          break;
        default:
          title = 'Login Error';
          message = e.message ?? 'An error occurred. Please try again.';
          await _logAuditEntry(null, 'unknown_error', 'Failed');
      }
      _showDialog(title, message);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null && user.emailVerified) {
        await _logLoginActivityAndTrustedDevice(user);

        final token = await user.getIdToken();
        if (token != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          await prefs.setString('userId', user.uid);
        }

        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => const Home(
                    activeIndex: 1,
                  )),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showDialog('Google Sign-In Failed', e.message ?? 'An error occurred.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logLoginActivityAndTrustedDevice(User user,
      {bool addToTrusted = true}) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    String deviceName = androidInfo.model ?? 'Unknown device';
    String platform = androidInfo.version.release ?? 'Unknown version';

    // Get local time in the Philippines
    Timestamp loginTime = Timestamp.now(); // Proper Firestore timestamp
// Local time (Philippine Time)

    String ipAddress = 'Unknown IP';
    String location = 'Unknown Location';

    try {
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=text'));
      if (response.statusCode == 200) {
        ipAddress = response.body;

        final locationResponse = await http.get(Uri.parse(
            'http://ip-api.com/json/$ipAddress')); // IP geolocation API
        if (locationResponse.statusCode == 200) {
          final locationData = locationResponse.body;
          final decodedLocationData = jsonDecode(locationData);
          location =
              "${decodedLocationData['city']}, ${decodedLocationData['regionName']}, ${decodedLocationData['country']}";
        }
      }
    } catch (e) {
      print('Failed to fetch IP address or location: $e');
    }

    // Logging login activity
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('loginActivity')
        .add({
      'deviceName': deviceName,
      'last_login': loginTime,
      'ipAddress': ipAddress,
      'location': location,
    });

    // Storing trusted devices
    if (addToTrusted) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trusted_devices')
          .doc(deviceName)
          .set({
        'device_name': deviceName,
        'ipAddress': ipAddress,
        'location': location,
        'last_login': loginTime,
        'platform': platform,
      });
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showDialog('Error', 'Please enter your email to reset the password.');
      return;
    }

    try {
      List<String> signInMethods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(_emailController.text.trim());

      if (signInMethods.isEmpty) {
        _showDialog('Error', 'No account found with this email.');
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      _showDialog(
          'Password Reset', 'Password reset email sent! Check your inbox.');
    } catch (e) {
      _showDialog(
          'Error', 'Failed to send password reset email. Please try again.');
    }
  }

  Future<bool> checkUserStatus(String? userId) async {
    try {
      if (userId == null) {
        return false;
      }

      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists &&
          userDoc.data() != null &&
          userDoc.data()!.containsKey('user_status')) {
        String userStatus = userDoc.data()!['user_status'];
        if (userStatus == 'active') {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking user status: $e');
      return false;
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/img/ibp_logo.png', // Replace with your logo path
                  height: 100.0, // Adjust height as needed
                ),
              ),
              const SizedBox(height: 24.0),
              const Center(
                child: Text(
                  'Welcome!',
                  style: TextStyle(
                    color: Color(0xFF580049),
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 48.0),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Ilagay ang iyong email',
                  labelStyle:
                      const TextStyle(fontSize: 16.0, color: Colors.black54),
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF580049)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24.0),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Ilagay ang iyong password',
                  labelStyle:
                      const TextStyle(fontSize: 16.0, color: Colors.black54),
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF580049)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_passwordVisible,
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text(
                    'Nakalimutan ang password?',
                    style: TextStyle(fontSize: 16, color: Color(0xFF580049)),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF580049),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _signIn,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUp()),
                    );
                  },
                  child: const Text(
                    'Wala pang account? Mag-Sign Up',
                    style: TextStyle(fontSize: 16, color: Color(0xFF580049)),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // const OrDivider(),
              // const SizedBox(height: 25),
              // ElevatedButton.icon(
              //   style: ElevatedButton.styleFrom(
              //     foregroundColor: Colors.black,
              //     backgroundColor: Colors.white,
              //     side: const BorderSide(
              //       color: Colors.grey,
              //       width: 1.0,
              //     ),
              //     minimumSize: const Size(double.infinity, 55),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              //   onPressed: _signInWithGoogle,
              //   icon: Image.asset(
              //     'assets/img/google_logo.png',
              //     height: 24,
              //   ),
              //   label: const Text(
              //     'Sign-In with Google',
              //     style: TextStyle(fontSize: 18),
              //   ),
              // ),
              // const SizedBox(height: 16),
              // ElevatedButton.icon(
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blue[800],
              //     minimumSize: const Size(double.infinity, 55),
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              //   onPressed:
              //       _showFacebookModal, // Call a function to show the modal
              //   icon: const Icon(Icons.facebook, color: Colors.white),
              //   label: const Text(
              //     'Sign-In with Facebook',
              //     style: TextStyle(fontSize: 18),
              //   ),
              // ),
              // const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            color: Colors.grey[400],
            height: 20,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'OR',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[400],
            height: 20,
          ),
        ),
      ],
    );
  }
}
