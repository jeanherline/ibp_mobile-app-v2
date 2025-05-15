import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'progress_bar.dart'; // Import the custom progress bar widget
import 'form_state_provider.dart';
import 'employment_profile.dart';

class ApplicantProfile extends StatefulWidget {
  const ApplicantProfile({super.key});

  @override
  _ApplicantProfileState createState() => _ApplicantProfileState();
}

class _ApplicantProfileState extends State<ApplicantProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _spouseNameController = TextEditingController();
  final TextEditingController _spouseOccupationController =
      TextEditingController();
  final TextEditingController _childrenNamesAgesController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final bool _isReadOnly = true; // set to false if you want to toggle later

  String? _selectedGender;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSavedFormValues();
    });
  }

  void _restoreSavedFormValues() {
    final formState = context.read<FormStateProvider>();

    setState(() {
      _fullNameController.text = formState.fullName ?? '';
      _dobController.text = formState.dob ?? '';
      _addressController.text = formState.address ?? '';
      _cityController.text = formState.city ?? '';
      _contactNumberController.text = formState.contactNumber ?? '';
      _selectedGender = formState.selectedGender ?? '';
      _spouseNameController.text = formState.spouseName ?? '';
      _spouseOccupationController.text = formState.spouseOccupation ?? '';
      _childrenNamesAgesController.text = formState.childrenNamesAges ?? '';
      _selectedCity = formState.city ?? '';
    });
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userData.exists) {
        setState(() {
          String displayName = userData['display_name'] ?? '';
          String middleName = userData['middle_name'] ?? '';
          String lastName = userData['last_name'] ?? '';

          _fullNameController.text = middleName.isNotEmpty
              ? '$displayName $middleName $lastName'.trim()
              : '$displayName $lastName'.trim();

          // Convert Timestamp to Date String
          if (userData['dob'] != null) {
            Timestamp dobTimestamp = userData['dob'];
            DateTime dobDate = dobTimestamp.toDate();
            _dobController.text =
                "${dobDate.year}-${dobDate.month}-${dobDate.day}";
          } else {
            _dobController.text = '';
          }
          _contactNumberController.text = userData['phone'] ?? '';
          _selectedGender = userData['gender'] ?? '';
          _spouseNameController.text = userData['spouse'] ?? '';
          _spouseOccupationController.text = userData['spouseOccupation'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _childrenNamesAgesController.text =
              userData['childrenNamesAges'] ?? '';
          _selectedCity = userData['city'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Isumite ang Suliraning Legal',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.055, // Responsive font size
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '(Submit your legal problem)',
              style: TextStyle(
                color: Colors.black87, // Darkened for better visibility
                fontSize: screenWidth * 0.035, // Responsive font size
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white, // Set the container background to white
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    const Center(
                      child: CustomProgressBar(currentStep: 2, totalSteps: 3),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Applicant\'s Profile',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Ang mga impormasyong ito ay ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'read-only',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                '. Kung kailangan baguhin, pakibago muna sa iyong profile.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '(These fields are read-only. If you need to make changes, please update your profile.)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      'Buong Pangalan',
                      'Full Name',
                      _fullNameController,
                      true,
                      'Ilagay ang buong pangalan (Enter full name)',
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildDateField(
                      'Araw ng Kapanganakan',
                      'Date of Birth',
                      _dobController,
                      'Ilagay ang araw ng kapanganakan (Enter date of birth)',
                      true,
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      'Adres o Tinitirahan',
                      'Street Address',
                      _addressController,
                      true,
                      'Ilagay ang adres o tinitirahan (Enter full address)',
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildCityDropdownField(screenWidth),
                    const SizedBox(height: 20),
                    _buildPhoneNumberField(
                      'Numero ng Telepono',
                      'Phone Number',
                      _contactNumberController,
                      'Ilagay ang iyong aktibong numero',
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      'Kasarian',
                      'Gender',
                      ['Male', 'Female', 'Other'],
                      _selectedGender,
                      'Piliin ang kasarian (Choose gender)',
                      true,
                      (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      'Pangalan ng Asawa',
                      'Spouse Name',
                      _spouseNameController,
                      false,
                      'Ilagay ang pangalan ng asawa (Enter spouse’s name)',
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      'Trabaho ng Asawa',
                      'Occupation of Spouse',
                      _spouseOccupationController,
                      false,
                      'Ilagay ang trabaho ng asawa (Enter spouse’s occupation)',
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildTextAreaField(
                      'Kung kasal, ilagay ang pangalan ng mga anak at edad nila',
                      'If married, write name of children and age',
                      _childrenNamesAgesController,
                      false,
                      'Ilagay ang pangalan at edad ng mga anak\n(Enter children’s name and age)',
                      screenWidth,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: const Color(0xFF580049),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final formState = context.read<FormStateProvider>();
                            formState.updateApplicantProfile(
                              fullName: _fullNameController.text,
                              dob: _dobController.text,
                              address: _addressController.text,
                              city: _selectedCity ?? '',
                              contactNumber: _contactNumberController.text,
                              selectedGender: _selectedGender ?? '',
                              spouseName: _spouseNameController.text,
                              spouseOccupation:
                                  _spouseOccupationController.text,
                              childrenNamesAges:
                                  _childrenNamesAgesController.text,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmploymentProfile(),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Sunod ',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.white,
                                ),
                                children: const <TextSpan>[
                                  TextSpan(
                                    text: '(Next)',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String subLabel,
    TextEditingController controller,
    bool isRequired,
    String hintText,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, isRequired, screenWidth),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          enabled: false,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black.withOpacity(0.6), // darker hint
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDateField(
      String label,
      String subLabel,
      TextEditingController controller,
      String hintText,
      bool isRequired,
      double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, isRequired, screenWidth),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true, // always read-only
          enabled: false,

          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black.withOpacity(0.6),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField(
    String label,
    String subLabel,
    TextEditingController controller,
    String helperText,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, true, screenWidth),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          readOnly: true,
          enabled: false,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            helperText: helperText,
            hintText: 'Ilagay ang numero ng telepono (Enter contact number)',
            hintStyle: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black.withOpacity(0.6),
            ),
            prefixText: controller.text.isEmpty ? '+63 ' : null,
            prefixStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF580049)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          onTap: () {
            if (controller.text.isEmpty) {
              controller.text = '+63 ';
            }
          },
          onChanged: (value) {
            if (value != '+63 ' && !value.startsWith('+63 ')) {
              controller.text = '+63 $value';
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildNumberField(
      String label,
      String subLabel,
      TextEditingController controller,
      String hintText,
      bool isRequired,
      double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, isRequired, screenWidth),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field cannot be empty';
            }
            // Regular expression to validate PH contact numbers
            final phContactNumberPattern = RegExp(r'^(09\d{9}|(\+639)\d{9})$');
            if (!phContactNumberPattern.hasMatch(value)) {
              return 'Please enter a valid PH contact number (e.g. 09XXXXXXXXX or +639XXXXXXXXX)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String subLabel,
    List<String> items,
    String? selectedItem,
    String hintText,
    bool isRequired,
    ValueChanged<String?> onChanged,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, isRequired, screenWidth),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedItem,
          onChanged: null,
          disabledHint: selectedItem != null
              ? Text(
                  selectedItem,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                )
              : Text(
                  hintText,
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black.withOpacity(0.6),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
          validator: isRequired
              ? (value) {
                  if (!_isReadOnly && (value == null || value.isEmpty)) {
                    return 'This field cannot be empty';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildTextAreaField(
    String label,
    String subLabel,
    TextEditingController controller,
    bool isRequired,
    String hintText,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, isRequired, screenWidth),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          enabled: false,
          maxLines: 4,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black.withOpacity(0.6),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildLabel(
      String label, String subLabel, bool isRequired, double screenWidth) {
    return RichText(
      text: TextSpan(
        text: '$label ',
        style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
        children: [
          TextSpan(
            text: '($subLabel)',
            style: TextStyle(
              color: Colors.grey[700], // Darker for better visibility
              fontSize: screenWidth * 0.04,
            ),
          ),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildCityDropdownField(double screenWidth) {
    const List<String> cities = [
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
      'Santa Maria',
    ];

    return _buildDropdownField(
      'Lungsod / Munisipalidad',
      'City / Municipality',
      cities,
      _selectedCity,
      'Piliin ang lungsod / munisipalidad (Choose city/municipality)',
      true,
      (value) {
        setState(() {
          _selectedCity = value;
        });
      },
      screenWidth,
    );
  }
}
