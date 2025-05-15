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
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Text(
                  'Tuntunin at Patakaran',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.black),
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

                    // Seksyon ng Patakaran sa Privacy
                    _buildSectionHeader(
                      'Patakaran sa Privacy para sa Philippine Electronic Legal Services and Access App',
                    ),
                    _buildSectionContent(
                        'Petsa ng Pagkakabisa: Oktubre 25, 2024'),
                    _buildSectionContent(
                      'Pinahahalagahan ng IBP Malolos Chapter ("kami") ang inyong privacy bilang mga gumagamit ng aming app ("ikaw"). Ipinapaliwanag ng Patakaran sa Privacy na ito kung paano namin kinokolekta, ginagamit, at pinoprotektahan ang iyong personal na impormasyon sa paggamit ng Philippine Electronic Legal Services and Access ("App").',
                    ),
                    _buildSectionHeader('1. Impormasyon na Kinokolekta Namin'),
                    _buildSectionContent(
                      'Maari naming kolektahin ang sumusunod na uri ng impormasyon:\n- Personal na Impormasyon: Pangalan, numero ng telepono, email address, at iba pang datos na kinakailangan sa pag-iskedyul ng appointment.\n- Detalye ng Appointment: Impormasyon kaugnay ng iyong konsultasyong legal at mga appointment.\n- Impormasyon ng Device: IP address, uri ng device, operating system, at iba pang teknikal na datos upang mapabuti ang performance ng App.',
                    ),
                    _buildSectionHeader(
                        '2. Paano Namin Ginagamit ang Iyong Impormasyon'),
                    _buildSectionContent(
                      'Ginagamit namin ang nakolektang impormasyon para sa mga sumusunod na layunin:\n- Para sa pag-iskedyul at pamamahala ng mga appointment sa IBP Malolos Chapter.\n- Para makapagpadala ng paalala at mahahalagang anunsyo tungkol sa iyong appointment.\n- Para mapabuti ang seguridad at kakayahan ng App.\n- Para matupad ang mga legal na obligasyon.',
                    ),
                    _buildSectionHeader('3. Pagbabahagi ng Datos'),
                    _buildSectionContent(
                      'Hindi namin ibinebenta, inuupa, o ibinabahagi ang iyong personal na impormasyon sa iba maliban kung:\n- Iniaatas ng batas o ng legal na proseso.\n- Sa mga service provider na tumutulong sa operasyon ng App, sa ilalim ng mahigpit na kasunduan sa pagiging kompidensyal.',
                    ),
                    _buildSectionHeader('4. Seguridad ng Datos'),
                    _buildSectionContent(
                      'Gumagamit kami ng standard na mga hakbang sa seguridad upang protektahan ang iyong datos. Gayunpaman, walang pamamaraan ng pagpapadala o pagtatago sa internet na ganap na ligtas. Bagaman nagsusumikap kami, hindi namin magagarantiyahan ang absolutong seguridad.',
                    ),
                    _buildSectionHeader('5. Iyong mga Karapatan'),
                    _buildSectionContent(
                      'May karapatan kang:\n- Ma-access ang iyong personal na datos.\n- Humiling ng pagwawasto sa maling impormasyon.\n- Humiling ng pagbura ng datos, maliban kung ito ay hinihingi ng batas.\n- Tumanggi sa hindi mahalagang pagkuha ng datos.',
                    ),
                    _buildSectionHeader(
                        '6. Mga Pagbabago sa Patakaran sa Privacy'),
                    _buildSectionContent(
                      'Maaring baguhin ang Patakaran sa Privacy na ito paminsan-minsan. Ipapabatid namin sa iyo ang mahahalagang pagbabago sa pamamagitan ng App o email.',
                    ),
                    _buildSectionHeader('7. Makipag-ugnayan sa Amin'),
                    _buildSectionContent(
                      'Para sa mga tanong o alalahanin kaugnay ng iyong privacy, mangyaring makipag-ugnayan sa amin sa ibpbulacanchapter@gmail.com.',
                    ),

                    const SizedBox(height: 24),

// Seksyon ng Mga Tuntunin at Kundisyon
                    _buildSectionHeader(
                      'Mga Tuntunin at Kundisyon para sa Philippine Electronic Legal Services and Access App',
                    ),
                    _buildSectionContent(
                        'Petsa ng Pagkakabisa: Oktubre 25, 2024'),
                    _buildSectionContent(
                      'Ang Mga Tuntunin at Kundisyon na ito ay sumasaklaw sa paggamit ng Philippine Electronic Legal Services and Access ("App"). Sa paggamit ng App, ikaw ay sumasang-ayon na sumunod sa mga tuntuning ito.',
                    ),
                    _buildSectionHeader('1. Pagtanggap sa Mga Tuntunin'),
                    _buildSectionContent(
                      'Sa paggamit ng App, sumasang-ayon kang sundin ang mga Tuntunin na ito at lahat ng naaangkop na batas. Ang mga tuntuning ito ay bumubuo ng legal na kasunduan sa pagitan mo ("Gumagamit") at ng IBP Malolos Chapter ("Kami").',
                    ),
                    _buildSectionHeader('2. Paggamit ng App'),
                    _buildSectionContent(
                      'Maaari mong gamitin ang App para sa mga sumusunod:\n- Pag-iskedyul ng appointment sa IBP Malolos Chapter.\n- Pamamahala at pagtingin ng iyong mga detalye ng appointment.',
                    ),
                    _buildSectionHeader('3. Account ng Gumagamit'),
                    _buildSectionContent(
                      'Upang magamit ang ilang bahagi ng App, maaaring kailanganin mong gumawa ng account. Sumasang-ayon kang:\n- Magbigay ng tamang impormasyon sa pagrehistro.\n- Panatilihing napapanahon ang iyong impormasyon.\n- Panatilihing ligtas ang iyong login details.\n- Ipabatid kaagad sa amin kung may kahina-hinalang paggamit ng iyong account.',
                    ),
                    _buildSectionHeader(
                        '4. Pag-iskedyul at Kanselasyon ng Appointment'),
                    _buildSectionContent(
                      'Ang mga appointment ay nakabatay sa availability. Bagama’t nagsusumikap kami sa pagbibigay ng tumpak na impormasyon, hindi namin magagarantiya ang availability ng tiyak na abogado o serbisyo.\n- Patakaran sa Kanselasyon: Maaari mong kanselahin o i-reschedule ang appointment sa pamamagitan ng App.',
                    ),
                    _buildSectionHeader('5. Karapatang Intelektwal'),
                    _buildSectionContent(
                      'Lahat ng nilalaman tulad ng teksto, larawan, logo, at software ay pagmamay-ari o lisensyado ng IBP Malolos Chapter at protektado sa ilalim ng batas ng karapatang intelektwal.',
                    ),
                    _buildSectionHeader('6. Privacy'),
                    _buildSectionContent(
                      'Ang paggamit mo ng App ay sakop din ng aming Patakaran sa Privacy. Sa paggamit ng App, sumasang-ayon kang mangolekta at gumamit kami ng impormasyon alinsunod sa patakarang iyon.',
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
                    'Malolos',
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
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                          children: [
                            const TextSpan(text: 'Sumasangayon ako sa mga '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  _showTermsAndConditionsModal(context);
                                },
                                child: const Text(
                                  'Mga Panuntunan sa Serbisyo at Patakaran sa Privacy',
                                  style: TextStyle(
                                    color: Color(0xFF407CE2),
                                    fontSize: 16,
                                    decoration: TextDecoration
                                        .none, // explicitly remove underline
                                  ),
                                ),
                              ),
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
