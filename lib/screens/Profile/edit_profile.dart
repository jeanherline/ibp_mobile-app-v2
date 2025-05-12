import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _spouseController = TextEditingController();
  final TextEditingController _spouseOccupationController =
      TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _employerNameController = TextEditingController();
  final TextEditingController _employerAddressController =
      TextEditingController();
  final TextEditingController _monthlyIncomeController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _childrenNamesAgesController =
      TextEditingController();

  String _barangayImageUrl = '';
  String _dswdImageUrl = '';
  String _paoImageUrl = '';

  File? _barangayImage;
  File? _dswdImage;
  File? _paoImage;

  String _photoUrl = '';
  DateTime _selectedDate = DateTime.now();
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedEmploymentType;
  String? _selectedCity;

  DateTime? _barangayUploadDate;
  DateTime? _dswdUploadDate;
  DateTime? _paoUploadDate;

  File? _imageFile;
  bool _isUploading = false;
  bool _hasChanges = false;

  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userData.data();

      if (data != null) {
        setState(() {
          _photoUrl = data['photo_url'] ?? '';
          _displayNameController.text = data['display_name'] ?? '';
          _middleNameController.text = data['middle_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          if (data['dob'] != null) {
            _selectedDate = (data['dob'] as Timestamp).toDate();
            _dobController.text =
                DateFormat('yyyy-MM-dd').format(_selectedDate);
          }
          _selectedCity = data['city'] ?? 'Select';
          _phoneController.text = data['phone'] ?? '';
          _selectedGender = data['gender'] ?? 'Select';
          _spouseController.text = data['spouse'] ?? '';
          _spouseOccupationController.text = data['spouseOccupation'] ?? '';
          _selectedMaritalStatus = data['maritalStatus'] ?? 'Select';
          final uploadedImages = data['uploadedImages'] ?? {};
          _barangayImageUrl = uploadedImages['barangayImageUrl'] ?? '';
          _dswdImageUrl = uploadedImages['dswdImageUrl'] ?? '';
          _paoImageUrl = uploadedImages['paoImageUrl'] ?? '';
          _barangayUploadDate =
              (uploadedImages['barangayImageUrlDateUploaded'] as Timestamp?)
                  ?.toDate();
          _dswdUploadDate =
              (uploadedImages['dswdImageUrlDateUploaded'] as Timestamp?)
                  ?.toDate();
          _paoUploadDate =
              (uploadedImages['paoImageUrlDateUploaded'] as Timestamp?)
                  ?.toDate();
          _occupationController.text = data['occupation'] ?? '';
          _employerNameController.text = data['employerName'] ?? '';
          _employerAddressController.text = data['employerAddress'] ?? '';
          _monthlyIncomeController.text = data['monthlyIncome'] ?? '';
          const validEmploymentTypes = [
            'Lokal na Trabaho (Local Employer/Agency)',
            'Dayuhang Amo (Foreign Employer)',
            'Sa sarili nagttrabaho (Self-Employed)',
            'Iba pa (Others)',
            'N/A'
          ];
          final fetchedType = data['employmentType'] ?? 'Select';
          _selectedEmploymentType =
              validEmploymentTypes.contains(fetchedType) ? fetchedType : null;

          _addressController.text = data['address'] ?? '';
          _childrenNamesAgesController.text = data['childrenNamesAges'] ?? '';

          _originalData = {
            'photo_url': _photoUrl,
            'display_name': _displayNameController.text,
            'middle_name': _middleNameController.text,
            'last_name': _lastNameController.text,
            'dob': _dobController.text,
            'phone': _phoneController.text,
            'gender': _selectedGender,
            'spouse': _spouseController.text,
            'spouseOccupation': _spouseOccupationController.text,
            'city': _selectedCity,
            'maritalStatus': _selectedMaritalStatus,
            'occupation': _occupationController.text,
            'employerName': _employerNameController.text,
            'employerAddress': _employerAddressController.text,
            'monthlyIncome': _monthlyIncomeController.text,
            'employmentType': _selectedEmploymentType,
            'address': _addressController.text,
            'childrenNamesAges': _selectedMaritalStatus == 'Single'
                ? 'N/A'
                : _childrenNamesAgesController.text,
            'uploadedImages': {
              'barangayImageUrl': _barangayImageUrl,
              'barangayImageUrlDateUploaded': _barangayUploadDate,
              'dswdImageUrl': _dswdImageUrl,
              'dswdImageUrlDateUploaded': _dswdUploadDate,
              'paoImageUrl': _paoImageUrl,
              'paoImageUrlDateUploaded': _paoUploadDate,
            }
          };

          _hasChanges = false; // Initially disable the button
        });
      }
    }
  }

  Future<Map<String, dynamic>> _uploadDocument(
      File file, String pathLabel) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final storageRef = FirebaseStorage.instance.ref().child(
          'documents/${user.uid}/${pathLabel}_$timestamp.png',
        );

    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    return {
      'url': downloadUrl,
      'date': Timestamp.now(),
    };
  }

  void _checkForChanges() {
    // This method will now check every single field, including the image selection
    Map<String, dynamic> updatedData = {
      'display_name': _displayNameController.text,
      'middle_name': _middleNameController.text,
      'last_name': _lastNameController.text,
      'dob': Timestamp.fromDate(_selectedDate),
      'phone': _phoneController.text,
      'gender': _selectedGender,
      'spouse': _spouseController.text,
      'spouseOccupation': _spouseOccupationController.text,
      'city': _selectedCity,
      'photo_url': _photoUrl,
      'maritalStatus': _selectedMaritalStatus,
      'occupation': _occupationController.text,
      'employerName': _employerNameController.text,
      'employerAddress': _employerAddressController.text,
      'monthlyIncome': _monthlyIncomeController.text,
      'employmentType': _selectedEmploymentType,
      'address': _addressController.text,
      'childrenNamesAges': _selectedMaritalStatus == 'Single'
          ? 'N/A'
          : _childrenNamesAgesController.text,
    };

    setState(() {
      _hasChanges = !_mapEquals(_originalData, updatedData) ||
          _imageFile != null ||
          _barangayImage != null ||
          _dswdImage != null ||
          _paoImage != null;
    });
  }

  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        _checkForChanges();
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _checkForChanges(); // Enable save button instantly after selecting image
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isUploading = true;
      });
      try {
        final now = DateTime.now();
        final timestamp =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';

        final storageRef = FirebaseStorage.instance.ref().child(
            'profile_images/${user.uid}/profileImage_$timestamp.png'); // Path with timestamp and folder structure

        await storageRef.putFile(_imageFile!);
        _photoUrl = await storageRef.getDownloadURL();
        setState(() {
          _isUploading = false;
          _imageFile = null; // Clear local image file
        });
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  ImageProvider _getImageProvider() {
    if (_imageFile != null) {
      return FileImage(_imageFile!); // Preview the selected image
    } else if (_photoUrl.isNotEmpty) {
      return NetworkImage(_photoUrl);
    } else {
      return const AssetImage('assets/img/DefaultUserImage.jpg');
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    const pattern = r'^(09\d{9}|\+639\d{9})$';
    if (!RegExp(pattern).hasMatch(value)) {
      return 'Please enter a valid PH phone number';
    }
    return null;
  }

  Widget _buildMultilineTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        onChanged: (value) => _checkForChanges(),
        maxLines: 3,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black, fontSize: 16.0),
              children: required
                  ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 16.0),
                      )
                    ]
                  : [],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
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
        title: const Text('Edit Profile'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: _checkForChanges,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.18, // Slightly smaller avatar
                    backgroundImage: _getImageProvider(),
                    backgroundColor: const Color(0xFFF5F5F5),
                  ),
                  InkWell(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      radius:
                          20, // Decrease the radius to make the background circle smaller
                      backgroundColor: Color(0xFF580049),
                      child: Icon(Icons.edit,
                          size: 18,
                          color:
                              Colors.white), // Adjust the icon size as needed
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField('First Name', _displayNameController,
                  required: true),
              _buildTextField('Middle Name', _middleNameController),
              _buildTextField('Last Name', _lastNameController, required: true),
              _buildDateField('Date of Birth', _dobController, context,
                  required: true),
              _buildPhoneField('Phone Number', _phoneController,
                  required: true),
              _buildDropdown(
                'Gender',
                _selectedGender,
                required: true,
                ['Male', 'Female', 'Other'],
                (newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                    _checkForChanges();
                  });
                },
              ),
              _buildDropdown(
                'Marital Status',
                _selectedMaritalStatus,
                ['Single', 'Married', 'Widowed', 'Separated'],
                (newValue) {
                  setState(() {
                    _selectedMaritalStatus = newValue!;
                    if (_selectedMaritalStatus == 'Single') {
                      _spouseController.text = 'N/A';
                      _spouseOccupationController.text = 'N/A';
                      _childrenNamesAgesController.text = 'N/A';
                    } else {
                      _spouseController.text = '';
                      _spouseOccupationController.text = '';
                      _childrenNamesAgesController.text = '';
                    }

                    _checkForChanges();
                  });
                },
                required: true,
              ),
              _buildTextField('Street Address', _addressController,
                  required: true),
              if (_selectedMaritalStatus != 'Single')
                _buildMultilineTextField(
                  'Children\'s Names and Ages',
                  _childrenNamesAgesController,
                  required: true,
                ),
              if (_selectedMaritalStatus == 'Single') ...[
                const SizedBox(), // Hides spouse fields
              ] else ...[
                _buildTextField('Spouse Name', _spouseController,
                    required: true),
                _buildTextField(
                    'Spouse Occupation', _spouseOccupationController,
                    required: true),
              ],
              _buildTextField(
                'Your Occupation',
                _occupationController,
                required: true,
                showNaButton: true,
                onNaPressed: () {
                  setState(() {
                    _occupationController.text = 'N/A';
                  });
                },
              ),
              _buildTextField(
                'Employer Name',
                _employerNameController,
                required: true,
                showNaButton: true,
                onNaPressed: () {
                  setState(() {
                    _employerNameController.text = 'N/A';
                  });
                },
              ),
              _buildTextField(
                'Employer Address',
                _employerAddressController,
                required: true,
                showNaButton: true,
                onNaPressed: () {
                  setState(() {
                    _employerAddressController.text = 'N/A';
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextFormField(
                  controller: _monthlyIncomeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[\d,]*$')),
                  ],
                  onChanged: (value) => _checkForChanges(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your monthly income';
                    }
                    if (!RegExp(r'^\d+(,\d{3})*$').hasMatch(value)) {
                      return 'Enter a valid number like 10,000';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    label: RichText(
                      text: const TextSpan(
                        text: 'Monthly Income',
                        style: TextStyle(color: Colors.black, fontSize: 16.0),
                        children: [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red, fontSize: 16.0),
                          )
                        ],
                      ),
                    ),
                    prefixText: '₱ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdown(
                    'Kind of Employment',
                    _selectedEmploymentType,
                    required: true,
                    [
                      'Lokal na Trabaho (Local Employer/Agency)',
                      'Dayuhang Amo (Foreign Employer)',
                      'Sa sarili nagttrabaho (Self-Employed)',
                      'Iba pa (Others)',
                      'N/A'
                    ],
                    (value) {
                      setState(() {
                        _selectedEmploymentType = value!;
                        _checkForChanges();
                      });
                    },
                  ),
                ],
              ),
              _buildDropdown(
                'City',
                _selectedCity,
                [
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
                  'Santa Maria',
                ],
                (newValue) {
                  setState(() {
                    _selectedCity = newValue!;
                    _checkForChanges();
                  });
                },
                required: true,
              ),
              _buildUploadButton(
                "Brgy. Certificate of Indigency",
                _barangayImage,
                context,
                imageUrl: _barangayImageUrl,
                uploadDate: _barangayUploadDate,
                key: ValueKey(_barangayUploadDate?.toIso8601String()),
                () async {
                  await showModalBottomSheet<ImageSource>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        height: 190, // ✅ increase modal height
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Pumili',
                                style: TextStyle(
                                  fontSize: 18, // ✅ make font 18px
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              title: const Text('Open Camera'),
                              onTap: () =>
                                  Navigator.pop(context, ImageSource.camera),
                            ),
                            ListTile(
                              title: const Text('Open Gallery'),
                              onTap: () =>
                                  Navigator.pop(context, ImageSource.gallery),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).then((source) async {
                    if (source != null) {
                      final picked =
                          await ImagePicker().pickImage(source: source);
                      if (picked != null) {
                        final tempDir = await getTemporaryDirectory();
                        final targetPath =
                            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                        final newImage =
                            await File(picked.path).copy(targetPath);
                        setState(() {
                          _barangayImage = newImage;
                          _checkForChanges();
                        });
                      }
                    }
                  });
                },
              ),
              _buildUploadButton(
                'DSWD Certificate of Indigency',
                _dswdImage,
                context,
                imageUrl: _dswdImageUrl,
                uploadDate: _dswdUploadDate,
                key: ValueKey(_dswdUploadDate?.toIso8601String()),
                () async {
                  await showModalBottomSheet<ImageSource>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        height: 190, // ✅ increase modal height
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Pumili',
                                style: TextStyle(
                                  fontSize: 18, // ✅ make font 18px
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              title: const Text('Open Camera'),
                              onTap: () =>
                                  Navigator.pop(context, ImageSource.camera),
                            ),
                            ListTile(
                              title: const Text('Open Gallery'),
                              onTap: () =>
                                  Navigator.pop(context, ImageSource.gallery),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).then((source) async {
                    if (source != null) {
                      final picked =
                          await ImagePicker().pickImage(source: source);
                      if (picked != null) {
                        final tempDir = await getTemporaryDirectory();
                        final targetPath =
                            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                        final newImage =
                            await File(picked.path).copy(targetPath);

                        setState(() {
                          _dswdImage = newImage;
                          _checkForChanges();
                        });
                      }
                    }
                  });
                },
              ),
              _buildUploadButton(
                  'PAO Disqualification Letter', _paoImage, context,
                  imageUrl: _paoImageUrl,
                  uploadDate: _paoUploadDate,
                  key: ValueKey(_paoUploadDate?.toIso8601String()), () async {
                await showModalBottomSheet<ImageSource>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      height: 190, // ✅ increase modal height
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Pumili',
                              style: TextStyle(
                                fontSize: 18, // ✅ make font 18px
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            title: const Text('Open Camera'),
                            onTap: () =>
                                Navigator.pop(context, ImageSource.camera),
                          ),
                          ListTile(
                            title: const Text('Open Gallery'),
                            onTap: () =>
                                Navigator.pop(context, ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).then((source) async {
                  if (source != null) {
                    final picked =
                        await ImagePicker().pickImage(source: source);
                    if (picked != null) {
                      final tempDir = await getTemporaryDirectory();
                      final targetPath =
                          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
                      final newImage = await File(picked.path).copy(targetPath);

                      setState(() {
                        _paoImage = newImage;
                        _checkForChanges();
                      });
                    }
                  }
                });
              }),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    String? prefixText,
    bool showNaButton = false,
    VoidCallback? onNaPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        onChanged: (value) => _checkForChanges(),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black, fontSize: 16.0),
              children: required
                  ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 16.0),
                      )
                    ]
                  : [],
            ),
          ),
          prefixText: prefixText,
          suffixIcon: showNaButton
              ? TextButton(
                  onPressed: onNaPressed,
                  child: const Text('N/A'),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPhoneField(String label, TextEditingController controller,
      {required bool required}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        onChanged: (value) {
          _checkForChanges();
        },
        validator: _validatePhoneNumber,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: required
                  ? [
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red, fontSize: 16))
                    ]
                  : [],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onTap: () {
          // Ensure the prefix "+63" is inserted only once
          if (!controller.text.startsWith('+63')) {
            controller.text = '+63';
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          }
        },
      ),
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller, BuildContext context,
      {required bool required}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: required
                  ? [
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red, fontSize: 16))
                    ]
                  : [],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF580049)),
            onPressed: () => _selectDate(context),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        readOnly: true,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    required bool required,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        validator: required
            ? (val) => val == null ? 'Please select $label' : null
            : null,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: required
                  ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      )
                    ]
                  : [],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15), // You can tweak this if needed
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _hasChanges &&
              !_isUploading &&
              _formKey.currentState?.validate() == true
          ? () async {
              setState(() => _isUploading = true); // start loading
              await _uploadImage(); // upload image
              await _saveProfile(); // save data
              setState(() => _isUploading = false); // end loading
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF580049),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isUploading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Save Changes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not authenticated')),
      );
      return;
    }

    // Fetch the current user data from Firestore
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userData.data();

    if (data == null) return;

    Map<String, dynamic> updatedData = {
      'display_name': _displayNameController.text,
      'middle_name': _middleNameController.text,
      'last_name': _lastNameController.text,
      'dob': Timestamp.fromDate(_selectedDate),
      'phone': _phoneController.text,
      'gender': _selectedGender,
      'spouse': _spouseController.text,
      'spouseOccupation': _spouseOccupationController.text,
      'city': _selectedCity,
      'photo_url': _photoUrl,
      'maritalStatus': _selectedMaritalStatus,
      'occupation': _occupationController.text,
      'employerName': _employerNameController.text,
      'employerAddress': _employerAddressController.text,
      'monthlyIncome': _monthlyIncomeController.text,
      'employmentType': _selectedEmploymentType,
      'address': _addressController.text,
      'childrenNamesAges': _selectedMaritalStatus == 'Single'
          ? 'N/A'
          : _childrenNamesAgesController.text,
    };

    // Fetch the most recent login activity for metadata
    final loginActivitySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('loginActivity')
        .orderBy('loginTime', descending: true)
        .limit(1)
        .get();

    // Initialize metadata values
    String ipAddress = 'Unknown';
    String userAgent = 'Unknown';

    if (loginActivitySnapshot.docs.isNotEmpty) {
      final latestLoginData = loginActivitySnapshot.docs.first.data();
      ipAddress = latestLoginData['ipAddress'] ?? 'Unknown';
      userAgent = latestLoginData['deviceName'] ?? 'Unknown';
    }

    // Calculate changes for audit logging
    Map<String, dynamic> changes = {};
    updatedData.forEach((key, value) {
      if (data[key] != value) {
        changes[key] = {'oldValue': data[key], 'newValue': value};
      }
    });

    Map<String, dynamic> uploadedImages =
        Map<String, dynamic>.from(data['uploadedImages'] ?? {});

// Upload & replace only if new file selected
    if (_barangayImage != null) {
      final result =
          await _uploadDocument(_barangayImage!, 'barangayCertificate');
      uploadedImages['barangayImageUrl'] = result['url'];
      uploadedImages['barangayImageUrlDateUploaded'] = result['date'];
      setState(() {
        _barangayImageUrl = result['url'];
        _barangayUploadDate = (result['date'] as Timestamp).toDate();
        _barangayImage = null;
      });
    }

    if (_dswdImage != null) {
      final result = await _uploadDocument(_dswdImage!, 'dswdCertificate');
      uploadedImages['dswdImageUrl'] = result['url'];
      uploadedImages['dswdImageUrlDateUploaded'] = result['date'];
      setState(() {
        _dswdImageUrl = result['url'];
        _dswdUploadDate = (result['date'] as Timestamp).toDate();
        _dswdImage = null;
      });
    }

    if (_paoImage != null) {
      final result = await _uploadDocument(_paoImage!, 'paoDisqualification');
      uploadedImages['paoImageUrl'] = result['url'];
      uploadedImages['paoImageUrlDateUploaded'] = result['date'];
      setState(() {
        _paoImageUrl = result['url'];
        _paoUploadDate = (result['date'] as Timestamp).toDate();
        _paoImage = null;
      });
    }

// ✅ Always attach to Firestore update
    updatedData['uploadedImages'] = uploadedImages;

    // Update user data in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update(updatedData);

    _originalData = updatedData; // Reset original data after saving
    _checkForChanges();

    // Send profile update notification
    await _sendProfileUpdateNotification(user.uid);

    // Add audit log entry for profile update
    await FirebaseFirestore.instance.collection('audit_logs').add({
      'actionType': 'UPDATE',
      'timestamp': FieldValue.serverTimestamp(),
      'uid': user.uid,
      'changes': changes,
      'affectedData': {
        'targetUserId': user.uid,
        'targetUserName': updatedData['display_name'],
      },
      'metadata': {
        'ipAddress': ipAddress,
        'userAgent': userAgent,
      },
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  Future<void> _sendProfileUpdateNotification(String uid) async {
    final notificationDoc =
        FirebaseFirestore.instance.collection('notifications').doc();

    String message = 'Your profile has been successfully updated.';

    await notificationDoc.set({
      'notifId': notificationDoc.id,
      'uid': uid,
      'message': message,
      'type': 'profile_update',
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _spouseController.dispose();
    _spouseOccupationController.dispose();
    super.dispose();
  }
}

Widget _buildUploadButton(
  String label,
  File? file,
  BuildContext context,
  VoidCallback onTap, {
  String? imageUrl,
  DateTime? uploadDate,
  required ValueKey<String?> key,
}) {
  final bool hasUploadedFile =
      file != null || (imageUrl != null && imageUrl.isNotEmpty);
  bool isExpired =
      uploadDate != null && DateTime.now().difference(uploadDate).inDays > 180;

  if (file != null) {
    // If a new file is picked, treat it as not expired yet (pending save)
    isExpired = false;
  }

  Color bgColor;
  IconData icon;
  String buttonText;

  if (isExpired) {
    bgColor = Colors.red;
    icon = Icons.error;
    buttonText = '$label ㄨ Expired';
  } else if (hasUploadedFile) {
    bgColor = Colors.green;
    icon = Icons.check_circle;
    buttonText = '$label ✓';
  } else {
    bgColor = Colors.blue;
    icon = Icons.upload_file;
    buttonText = label;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (hasUploadedFile) {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.image),
                            title: const Text('View Image'),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.black87,
                                  insetPadding: const EdgeInsets.all(20),
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: InteractiveViewer(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: file != null
                                            ? Image.file(file)
                                            : Image.network(
                                                imageUrl!,
                                                fit: BoxFit.contain,
                                                loadingBuilder:
                                                    (context, child, progress) {
                                                  if (progress == null)
                                                    return child;
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                },
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.upload),
                            title: const Text('Reupload'),
                            onTap: () {
                              Navigator.pop(context);
                              onTap(); // trigger picker again
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else {
                onTap(); // open picker for first upload
              }
            },
            icon: Icon(icon),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
