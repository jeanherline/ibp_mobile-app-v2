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

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
      }

      if (user != null && user.emailVerified) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'user_status': 'active'});

        await _logLoginActivityAndTrustedDevice(user);

        final token = await user.getIdToken();

        if (token != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          await prefs.setString('userId', user.uid);
        }
      }

      bool isActive = await checkUserStatus(user?.uid);

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
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      _showDialog('Sign In Failed', message);
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
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'display_name': user.displayName,
          'email': user.email,
          'user_status': 'active',
          'created_time': DateTime.now(),
        }, SetOptions(merge: true));

        await _logLoginActivityAndTrustedDevice(user);

        final token = await user.getIdToken();
        if (token != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          await prefs.setString('userId', user.uid);
        }

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

  Future<void> _logLoginActivityAndTrustedDevice(User user) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    String deviceName = androidInfo.model ?? 'Unknown device';
    String platform = androidInfo.version.release ?? 'Unknown version';

    // Get local time in the Philippines
    String loginTime =
        DateTime.now().toIso8601String(); // Local time (Philippine Time)

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
      'loginTime': loginTime,
      'ipAddress': ipAddress,
      'location': location,
    });

    // Storing trusted devices
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('trusted_devices')
        .doc(deviceName) // Use device name as the document ID
        .set({
      'device_name': deviceName,
      'ipAddress': ipAddress,
      'location': location,
      'last_login': loginTime,
      'platform': platform,
    });
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
              const OrDivider(),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _signInWithGoogle,
                icon: Image.asset(
                  'assets/img/google_logo.png',
                  height: 24,
                ),
                label: const Text(
                  'Sign-In with Google',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  minimumSize: const Size(double.infinity, 55),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    _showFacebookModal, // Call a function to show the modal
                icon: const Icon(Icons.facebook, color: Colors.white),
                label: const Text(
                  'Sign-In with Facebook',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
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
