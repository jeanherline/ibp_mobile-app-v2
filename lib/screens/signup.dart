import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String _passwordStrength = 'Weak';
  Color _passwordStrengthColor = Colors.red;
  bool _showPasswordStrength = false;
  final FocusNode _passwordFocusNode = FocusNode();
  bool _showPasswordRequirements = false;
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? _selectedCity;

  void _checkPasswordStrength(String password) {
    String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{10,}$';
    RegExp regex = RegExp(pattern);

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 'Weak';
        _passwordStrengthColor = Colors.red;
      });
    } else if (password.length < 10) {
      setState(() {
        _passwordStrength = 'Too Short';
        _passwordStrengthColor = Colors.red;
      });
    } else if (!regex.hasMatch(password)) {
      setState(() {
        _passwordStrength = 'Weak';
        _passwordStrengthColor = Colors.red;
      });
    } else {
      setState(() {
        _passwordStrength = 'Strong';
        _passwordStrengthColor = Colors.green;
      });
    }
  }

  Future<String> _generateQrCodeImageUrl(String uid) async {
    final qrValidationResult = QrValidator.validate(
      data: uid,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: Colors.white,
        gapless: false,
      );
      final image = await painter.toImage(200);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      final fileName = 'user_qr_code_$uid.png';
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_qr_codes');
      final uploadTask = storageRef.child(fileName).putData(buffer);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } else {
      throw Exception('Failed to generate QR code');
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_agreedToTerms) {
        setState(() {
          _isLoading = true;
        });
        try {
          UserCredential userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          User? user = userCredential.user;
          if (user != null) {
            String qrCodeUrl = await _generateQrCodeImageUrl(user.uid);

            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'uid': user.uid,
              'display_name': _firstNameController.text.trim(),
              'middle_name': _middleNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'email': _emailController.text.trim(),
              'city': _selectedCity,
              'member_type': 'client',
              'user_status': 'inactive',
              'created_time': DateTime.now(),
              'userQrCode': qrCodeUrl,
            });

            await user.sendEmailVerification();

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Success'),
                content: const Text(
                    'Your information has been submitted. Please check your email for verification.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            throw Exception('No user found.');
          }
        } catch (e) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign Up Failed'),
              content: Text('An error occurred: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Terms Not Accepted'),
            content: const Text(
                'You must agree to the terms of service and privacy policy to sign up.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color.fromARGB(221, 0, 0, 0),
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          color: Color.fromARGB(136, 0, 0, 0),
        ),
      ),
    );
  }

  void _showTermsAndConditionsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                15.0), // Rounded corners for modern design
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 20.0,
          ), // Padding around the dialog for a more centered and responsive look
          child: Padding(
            padding:
                const EdgeInsets.all(16.0), // Internal padding inside the modal
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Text('Terms & Conditions and Privacy Policy'),
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
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // IBP Logo at the top center
                    Center(
                      child: Image.asset(
                        'assets/img/ibp_logo.png', // Replace with your actual logo asset path
                        height: 100,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Privacy Policy Section
                    _buildSectionHeader(
                      'Privacy Policy for Philippine Electronic Legal Services and Access App',
                    ),
                    _buildSectionContent('Effective Date: October 25, 2024'),
                    _buildSectionContent(
                      'The IBP Malolos Chapter ("we," "our," or "us") values the privacy of our users ("you" or "your"). This Privacy Policy explains how we collect, use, and protect your personal information when you use our Philippine Electronic Legal Services and Access ("App").',
                    ),
                    _buildSectionHeader('1. Information We Collect'),
                    _buildSectionContent(
                      'We may collect the following types of information:\n- Personal Identification Information: Name, phone number, email address, and other relevant data needed for appointment scheduling.\n- Appointment Details: Information related to your legal consultations and appointments.\n- Device Information: IP address, device type, operating system, and other technical data to improve the App’s performance.',
                    ),
                    _buildSectionHeader('2. How We Use Your Information'),
                    _buildSectionContent(
                      'We use the information collected for the following purposes:\n- To schedule and manage appointments with IBP Malolos Chapter members.\n- To communicate appointment reminders and other important updates.\n- To improve the functionality and security of the App.\n- To comply with legal obligations.',
                    ),
                    _buildSectionHeader('3. Data Sharing'),
                    _buildSectionContent(
                      'We do not share, sell, or rent your personal information to third parties, except:\n- When required by law or legal proceedings.\n- With service providers who help us operate the App, under strict confidentiality agreements.',
                    ),
                    _buildSectionHeader('4. Data Security'),
                    _buildSectionContent(
                      'We implement industry-standard security measures to protect your data. However, no method of transmission over the internet or electronic storage is completely secure. We cannot guarantee absolute security but strive to protect your information to the best of our ability.',
                    ),
                    _buildSectionHeader('5. Your Rights'),
                    _buildSectionContent(
                      'You have the right to:\n- Access your personal data.\n- Request corrections to inaccurate data.\n- Request deletion of your data, except when required by law.\n- Opt out of non-essential data collection.',
                    ),
                    _buildSectionHeader('6. Changes to This Privacy Policy'),
                    _buildSectionContent(
                      'We may update this Privacy Policy from time to time. You will be notified of any significant changes via the App or email.',
                    ),
                    _buildSectionHeader('7. Contact Us'),
                    _buildSectionContent(
                      'For questions or concerns regarding your privacy, please contact us at ibpbulacanchapter@gmail.com.',
                    ),

                    const SizedBox(height: 24), // Space before the next section

                    // Terms and Conditions Section
                    _buildSectionHeader(
                        'Terms and Conditions for Philippine Electronic Legal Services and Access App'),
                    _buildSectionContent('Effective Date: October 25, 2024'),
                    _buildSectionContent(
                      'These Terms and Conditions govern your use of the Philippine Electronic Legal Services and Access ("App"). By accessing or using the App, you agree to be bound by these Terms.',
                    ),
                    _buildSectionHeader('1. Acceptance of Terms'),
                    _buildSectionContent(
                      'By accessing the App, you agree to comply with these Terms and all applicable laws. These Terms form a legal agreement between you ("User") and the IBP Malolos Chapter ("We," "Us," or "Our").',
                    ),
                    _buildSectionHeader('2. Use of the App'),
                    _buildSectionContent(
                      'You may use the App for the following purposes:\n- Scheduling appointments with the IBP Malolos Chapter.\n- Managing and viewing your appointment details.',
                    ),
                    _buildSectionHeader('3. User Accounts'),
                    _buildSectionContent(
                      'To use certain features of the App, you may need to create an account. You agree to:\n- Provide accurate and complete information during registration.\n- Keep your account information up-to-date.\n- Maintain the confidentiality of your account login details.\n- Notify us immediately if you suspect unauthorized use of your account.',
                    ),
                    _buildSectionHeader(
                        '4. Appointment Scheduling and Cancellation'),
                    _buildSectionContent(
                      'Appointments scheduled through the App are subject to availability. While we strive to ensure accurate appointment information, we do not guarantee the availability of specific lawyers or services.\n- Cancellation Policy: You may cancel or reschedule appointments through the App.',
                    ),
                    _buildSectionHeader('5. Intellectual Property'),
                    _buildSectionContent(
                      'All content, including but not limited to text, images, logos, and software, is owned by or licensed to the IBP Malolos Chapter and is protected by copyright and other intellectual property laws.',
                    ),
                    _buildSectionHeader('6. Privacy'),
                    _buildSectionContent(
                      'Your use of the App is also governed by our Privacy Policy, which explains how we collect, use, and share your information. By using the App, you consent to the collection and use of your data in accordance with our Privacy Policy.',
                    ),

                    const SizedBox(height: 24),
                    // Agree Button at the bottom
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF580049),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _agreedToTerms = true;
                        });
                      },
                      child: const Text(
                        'Agree',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF580049),
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 48.0),
                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Ilagay ang iyong first name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // Middle Name
                TextFormField(
                  controller: _middleNameController,
                  decoration: InputDecoration(
                    labelText: 'Ilagay ang iyong middle name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Ilagay ang iyong last name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Ilagay ang iyong email *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      focusNode: _passwordFocusNode,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Ilagay ang iyong password *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
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
                      onChanged: (password) {
                        setState(() {
                          _showPasswordStrength = true;
                        });
                        _checkPasswordStrength(password);
                      },
                      onTap: () {
                        setState(() {
                          _showPasswordRequirements = true;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (_passwordStrength != 'Strong') {
                          return 'Password must meet the criteria';
                        }
                        return null;
                      },
                    ),
                    if (_showPasswordRequirements)
                      const Column(
                        children: [
                          SizedBox(height: 10.0),
                          Text(
                            'Password must be at least 10 characters long and include: \n'
                            '- Upper and lowercase letters \n'
                            '- Numbers \n'
                            '- Symbols \n'
                            'Avoid using common words or personal information.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ],
                      ),
                    if (_showPasswordStrength)
                      Column(
                        children: [
                          const SizedBox(height: 10.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Password Strength: ',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                _passwordStrength,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _passwordStrengthColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Ilagay ang iyong password muli *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_confirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // City Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Lungsod/Bayan *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  items: const [
                    'Angat',
                    'Balagtas',
                    'Baliuag',
                    'Bocaue',
                    'Bulakan',
                    'Bustos',
                    'Calumpit',
                    'Doña Remedios Trinidad',
                    'Guiguinto',
                    'Hagonoy',
                    'Marilao',
                    'Norzagaray',
                    'Obando',
                    'Pandi',
                    'Paombong',
                    'Plaridel',
                    'Pulilan',
                    'San Ildefonso',
                    'San Miguel',
                    'San Rafael',
                    'Santa Maria'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCity = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // Terms Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (bool? value) {
                        if (value == true) {
                          _showTermsAndConditionsModal(context);
                        } else {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        }
                      },
                    ),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 16, color: Colors.black),
                          children: [
                            TextSpan(text: 'Sumasangayon ako sa mga '),
                            TextSpan(
                              text:
                                  'Tuntunin ng Serbisyo at Patakaran sa Privacy',
                              style: TextStyle(color: Color(0xFF407CE2)),
                            ),
                          ],
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24.0),

                // Sign Up Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF580049),
                          minimumSize: const Size(double.infinity, 55),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _signUp,
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Meron nang account? Mag-Sign in',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF580049),
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
}
