import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check if the user is logged in
        User? user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          throw FirebaseAuthException(
            code: 'no-user',
            message: 'No user is currently authenticated.',
          );
        }

        String email = user.email ?? '';

        // Re-authenticate the user with the old password
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: _oldPasswordController.text, // Old password from the form
        );

        // Reauthenticate the user
        await user.reauthenticateWithCredential(credential);

        // If successful, update the password
        await user.updatePassword(_newPasswordController.text);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session Expired')),
        );

        // Log out the user after password change
        await FirebaseAuth.instance.signOut();

        // Redirect to the login screen
        Navigator.of(context).pushReplacementNamed('/login');
      } on FirebaseAuthException catch (e) {
        // Define error message based on Firebase error codes
        String errorMessage;

        if (e.code == 'wrong-password') {
          errorMessage = 'The old password is incorrect.';
        } else if (e.code == 'weak-password') {
          errorMessage =
              'The new password is too weak. Please use a stronger password.';
        } else if (e.code == 'no-user') {
          errorMessage = 'No authenticated user found. Please log in again.';
        } else if (e.code == 'user-mismatch') {
          errorMessage = 'User credentials do not match.';
        } else if (e.code == 'requires-recent-login') {
          errorMessage = 'Please log in again to perform this action.';
        } else {
          errorMessage = 'An unknown error occurred. Please try again.';
        }

        // Show the error message in a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        // Stop loading spinner after operation
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
        title: const Text('Change Password'),
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
                _buildPasswordInput(
                  controller: _oldPasswordController,
                  label: 'Old Password',
                  obscureText: _obscureOldPassword,
                  toggleVisibility: () {
                    setState(() {
                      _obscureOldPassword = !_obscureOldPassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordInput(
                  controller: _newPasswordController,
                  label: 'New Password',
                  obscureText: _obscureNewPassword,
                  toggleVisibility: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordInput(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  obscureText: _obscureConfirmPassword,
                  toggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
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
                          onPressed: _changePassword,
                          child: Text(
                            'Change Password',
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

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your $label';
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
            hintText: 'Enter your $label', // Placeholder text
            hintStyle: const TextStyle(
              color: Colors.grey, // Light gray placeholder text
              fontSize: 14, // Adjust the size if needed
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}
