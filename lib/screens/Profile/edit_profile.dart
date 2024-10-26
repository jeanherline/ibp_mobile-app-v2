import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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

  String _photoUrl = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedCity = 'Angat';
  String _selectedGender = 'Male';
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
          _selectedCity = data['city'] ?? 'Angat';
          _phoneController.text = data['phone'] ?? '';
          _selectedGender = data['gender'] ?? 'Male';
          _spouseController.text = data['spouse'] ?? '';
          _spouseOccupationController.text = data['spouseOccupation'] ?? '';

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
          };
          _hasChanges = false; // Initially disable the button
        });
      }
    }
  }

  void _checkForChanges() {
    // This method will now check every single field, including the image selection
    Map<String, dynamic> updatedData = {
      'photo_url':
          _imageFile != null ? 'new_image' : _photoUrl, // Track new image
      'display_name': _displayNameController.text,
      'middle_name': _middleNameController.text,
      'last_name': _lastNameController.text,
      'dob': _dobController.text,
      'phone': _phoneController.text,
      'gender': _selectedGender,
      'spouse': _spouseController.text,
      'spouseOccupation': _spouseOccupationController.text,
      'city': _selectedCity,
    };

    setState(() {
      _hasChanges =
          !_mapEquals(_originalData, updatedData) || _imageFile != null;
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
              _buildTextField('First Name', _displayNameController),
              _buildTextField('Middle Name', _middleNameController),
              _buildTextField('Last Name', _lastNameController),
              _buildDateField('Date of Birth', _dobController, context),
              _buildPhoneField('Phone Number', _phoneController),
              _buildDropdown(
                'Gender',
                _selectedGender,
                ['Male', 'Female', 'Other'],
                (newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                    _checkForChanges();
                  });
                },
              ),
              _buildTextField('Spouse Name', _spouseController),
              _buildTextField('Spouse Occupation', _spouseOccupationController),
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
              ),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        onChanged: (value) {
          _checkForChanges();
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5), // Light gray fill for consistency
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPhoneField(String label, TextEditingController controller) {
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
          labelText: label,
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

  Widget _buildDateField(
      String label, TextEditingController controller, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
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

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _hasChanges && _formKey.currentState?.validate() == true
          ? () async {
              await _uploadImage(); // Upload image if selected
              await _saveProfile(); // Save the profile
            }
          : null, // Disable button if no changes or invalid input
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF580049),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(
            double.infinity, 50), // Full width button with proper size
      ),
      child: const Text(
        'Save Changes',
        style: TextStyle(
            fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedData);

      _originalData = updatedData; // Reset original data after saving
      _checkForChanges();

      await _sendProfileUpdateNotification(user.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
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
