import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangeEmailAddressPage extends StatefulWidget {
  const ChangeEmailAddressPage({super.key});

  @override
  _ChangeEmailAddressPageState createState() => _ChangeEmailAddressPageState();
}

class _ChangeEmailAddressPageState extends State<ChangeEmailAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? currentEmail;

  @override
  void initState() {
    super.initState();
    _fetchCurrentEmail();
  }

  Future<void> _fetchCurrentEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentEmail = user.email;
      });
    }
  }

  // First define the email existence checking function
  Future<bool> _checkEmailExistsInFirestore(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isNotEmpty; // If any documents exist, return true
  }

  Future<void> _updateEmailAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the current user
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'no-user',
            message: 'No user is currently authenticated.',
          );
        }

        // Check if the new email already exists in Firestore
        final emailExists =
            await _checkEmailExistsInFirestore(_emailController.text.trim());
        if (emailExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('This email is already in use by another account.')),
          );
          return; // Stop execution if email exists
        }

        // Re-authenticate the user with their password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: _passwordController.text.trim(),
        );

        // Attempt to reauthenticate
        await user.reauthenticateWithCredential(credential);

        // Send verification email to the new email address and update only after verification
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());

        // Show dialog that verification link has been sent
        _showVerificationSentDialog();
      } on FirebaseAuthException catch (e) {
        String errorMessage;

        // Enhanced error handling
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'email-already-in-use':
            errorMessage = 'This email is already in use.';
            break;
          case 'no-user':
            errorMessage = 'No authenticated user found.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is badly formatted.';
            break;
          case 'requires-recent-login':
            errorMessage = 'Please log in again to perform this action.';
            break;
          default:
            errorMessage = 'An error occurred: ${e.message}';
        }

        // Show the error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        // Catch any unexpected errors
        print('Unexpected error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// After the user logs in again, update the Firestore `users` collection
  Future<void> _updateFirestoreEmail(String userId, String newEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'email': newEmail});
    } catch (e) {
      print('Error updating Firestore: $e');
    }
  }

// Call this after the user has logged back in
  void _checkVerificationAndUpdateFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      // If the user is verified, update Firestore with the new email
      await _updateFirestoreEmail(user.uid, user.email!);
    }
  }

  void _showVerificationSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Verification Email Sent',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          content: const Text(
            'A verification link has been sent to your new email address. Please check your inbox and verify your email. After verification, please return to the app and log in again.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
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
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
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

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
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
        title: const Text('Change Email Address'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentEmail != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20), // Add some vertical padding
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Light grey background
                        borderRadius:
                            BorderRadius.circular(8), // Rounded corners
                      ),
                      child: Text(
                        'Current Email: $currentEmail',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                _buildEmailInput(),
                const SizedBox(height: 20),
                _buildPasswordInput(),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF580049),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: _updateEmailAddress,
                          child: Text(
                            'Update Email Address',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Email Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your new email address';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            hintText: 'Enter your new email address',
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            hintText: 'Enter your password',
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
