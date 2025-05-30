import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ibp_app_ver2/screens/Konsulta/konsulta_submit.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'form_state_provider.dart';
import 'progress_bar.dart';

class PAODisqualificationLetter extends StatefulWidget {
  const PAODisqualificationLetter({super.key});

  @override
  _PAODisqualificationLetterState createState() =>
      _PAODisqualificationLetterState();
}

class _PAODisqualificationLetterState extends State<PAODisqualificationLetter> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isChecked = false;

  Future<void> _pickImage(BuildContext context) async {
    final formStateProvider =
        Provider.of<FormStateProvider>(context, listen: false);

    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsDataUrl(files[0]);
          reader.onLoadEnd.listen((event) {
            final imageDataUrl = reader.result as String;
            if (mounted) {
              formStateProvider.setPAOSelectedImage(NetworkImage(imageDataUrl));
            }
          });
        }
      });
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final pickedFile = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      if (mounted) {
                        formStateProvider.setPAOSelectedImage(
                            FileImage(File(pickedFile.path)));
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final pickedFile = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (pickedFile != null) {
                      if (mounted) {
                        formStateProvider.setPAOSelectedImage(
                            FileImage(File(pickedFile.path)));
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formStateProvider = Provider.of<FormStateProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '(Submit your legal problem)',
              style: TextStyle(
                color: Colors.black87,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
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
                    child: CustomProgressBar(currentStep: 5, totalSteps: 6),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Disqualification Letter from PAO',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '(Attach your Disqualification Letter from PAO)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _pickImage(context),
                    child: Stack(
                      children: [
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            image: formStateProvider.paoSelectedImage != null
                                ? DecorationImage(
                                    image: formStateProvider.paoSelectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: formStateProvider.paoSelectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'I-click para piliin ang mga image files na nais mong i-upload.',
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      '(Click to select the image files you wish to upload.)',
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        if (formStateProvider.paoSelectedImage != null)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sineseryoso namin ang mga isyu sa privacy. Maaari kang makasiguro na ang iyong personal na data ay ligtas na nakaprotekta.',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'We take privacy issues seriously. You can be sure that your personal data is safely protected.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isChecked = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Naiintindihan ko ang mga katanungan at aking pinanunumpaan ang aking mga kasagutan at mga ibinigay na mga dokumento ay totoo at wasto.',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '(I fully understood all questions asked in this form and swear on the truth and veracity of my answers, and documents provided are true and correct.)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: screenWidth * 0.035,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      onPressed: () async {
                        if (formStateProvider.paoSelectedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please upload an image before proceeding.'),
                            ),
                          );
                          return;
                        }

                        if (!_isChecked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please accept the declaration.'),
                            ),
                          );
                          return;
                        }

                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );

                        // Save form data and images to Firestore and Firebase Storage
                        await _saveFormData(context);

                        // Hide loading indicator
                        if (mounted) {
                          Navigator.of(context).pop();
                        }

                        // Show success message and navigate to KonsultaSubmit
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Form submitted successfully'),
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KonsultaSubmit(
                              controlNumber:
                                  formStateProvider.controlNumber ?? '',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: 'Isumite ',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white,
                              ),
                              children: const <TextSpan>[
                                TextSpan(
                                  text: '(Submit)',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
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
    );
  }

  Future<void> _saveFormData(BuildContext context) async {
    final formStateProvider = context.read<FormStateProvider>();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not authenticated')),
      );
      return;
    }

    // Generate control number
    final controlNumber = generateControlNumber();
    formStateProvider.setControlNumber(controlNumber);

    final fullName = formStateProvider.fullName
        .replaceAll(' ', ''); // Remove spaces from full name

    final userDoc = FirebaseFirestore.instance
        .collection('appointments')
        .doc(controlNumber);
    final usersDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final now = DateTime.now();
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('konsulta_user_uploads/${user.uid}/$controlNumber/');

    // Ensure contact number starts with +63
    String contactNumber = formStateProvider.contactNumber.trim();
    if (!contactNumber.startsWith('+63')) {
      contactNumber = '+63 $contactNumber';
    }

    try {
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

      // Upload images to Firebase Storage
      final barangayImageUrl = await _uploadImage(
          storageRef,
          '${fullName}_${controlNumber}_barangayCertificateOfIndigency',
          formStateProvider.barangaySelectedImage);
      final dswdImageUrl = await _uploadImage(
          storageRef,
          '${fullName}_${controlNumber}_dswdCertificateOfIndigency',
          formStateProvider.dswdSelectedImage);
      final paoImageUrl = await _uploadImage(
          storageRef,
          '${fullName}_${controlNumber}_paoDisqualificationLetter',
          formStateProvider.paoSelectedImage);

      // Generate QR code image URL
      final qrCodeImageUrl =
          await _generateQrCodeImageUrl(controlNumber, storageRef);

      // Save form data to the appointments collection in Firestore
      await userDoc.set({
        'createdDate': FieldValue.serverTimestamp(),
        'updatedTime': FieldValue.serverTimestamp(),
        'read': 'false',
        'applicantProfile': {
          'uid': user.uid,
          'address': formStateProvider.address,
          'city': formStateProvider.city,
          'childrenNamesAges': formStateProvider.childrenNamesAges,
          'contactNumber': formStateProvider.contactNumber,
          'dob': formStateProvider.dob,
          'fullName': formStateProvider.fullName,
          'selectedGender': formStateProvider.selectedGender,
          'spouseName': formStateProvider.spouseName,
          'spouseOccupation': formStateProvider.spouseOccupation,
        },
        'appointmentDetails': {
          'appointmentStatus': 'pending',
          'controlNumber': controlNumber,
          'apptType': 'Via App',
          'qrCode': qrCodeImageUrl,
        },
        'legalAssistanceRequested': {
          'desiredSolutions': formStateProvider.desiredSolutions,
          'problemReason': formStateProvider.problemReason,
          'problems': formStateProvider.problems,
          'selectedAssistanceType': formStateProvider.selectedAssistanceType,
        },
        'employmentProfile': {
          'employerAddress': formStateProvider.employerAddress,
          'employerName': formStateProvider.employerName,
          'kindOfEmployment': formStateProvider.kindOfEmployment,
          'monthlyIncome': formStateProvider.monthlyIncome,
          'occupation': formStateProvider.occupation,
        },
        'uploadedImages': {
          'barangayImageUrl': barangayImageUrl,
          'dswdImageUrl': dswdImageUrl,
          'paoImageUrl': paoImageUrl,
        },
      });

      // Save partial user profile updates
      await usersDoc.set({
        'dob': formStateProvider.dob,
        'phone': formStateProvider.contactNumber,
        'gender': formStateProvider.selectedGender,
        'spouse': formStateProvider.spouseName,
        'spouseOccupation': formStateProvider.spouseOccupation,
        'city': formStateProvider.city,
        'updated_time': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge with existing data if any

      // Audit log for creating a new appointment
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'actionType': 'CREATE',
        'timestamp': FieldValue.serverTimestamp(),
        'uid': user.uid,
        'changes': {
          'appointmentDetails.controlNumber': {
            'oldValue': null,
            'newValue': controlNumber
          },
          'appointmentDetails.appointmentStatus': {
            'oldValue': null,
            'newValue': 'pending'
          },
          'appointmentDetails.qrCode': {
            'oldValue': null,
            'newValue': qrCodeImageUrl
          },
        },
        'affectedData': {
          'targetUserId': user.uid,
          'targetUserName': formStateProvider.fullName,
        },
        'metadata': {
          'ipAddress': ipAddress,
          'userAgent': userAgent,
        },
      });

      // Notify the current user
      await _sendNotification(
        uid: user.uid,
        message:
            'Your appointment request with Ticket Number $controlNumber has been submitted successfully. Please wait for the confirmation of the date and type of appointment.',
        type: 'appointment',
        controlNumber: controlNumber,
      );

      // Notify head lawyers
      final headLawyersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('member_type', isEqualTo: 'head')
          .get();

      for (final doc in headLawyersSnapshot.docs) {
        await _sendNotification(
          uid: doc.id,
          message:
              'A new appointment request has been submitted with (ID:$controlNumber) and is awaiting your approval.',
          type: 'appointment',
          controlNumber: controlNumber,
        );
      }

      // Navigate to KonsultaSubmit page after successful form submission
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KonsultaSubmit(
            controlNumber: formStateProvider.controlNumber ?? '',
          ),
        ),
      );
      Provider.of<FormStateProvider>(context, listen: false).clearFormState();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form submitted successfully'),
        ),
      );
    } catch (e) {
      // Show error message and stop loading if an error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit form: $e')),
      );
    }
  }

  Future<void> _sendNotification({
    String? uid,
    String? memberType,
    required String message,
    required String type,
    required String controlNumber,
  }) async {
    final notificationDoc =
        FirebaseFirestore.instance.collection('notifications').doc();
    await notificationDoc.set({
      'notifId': notificationDoc.id,
      'uid': uid,
      'member_type': memberType,
      'message': message,
      'type': type,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
      'controlNumber': controlNumber
    });
  }

  Future<String?> _uploadImage(
      Reference storageRef, String imageType, ImageProvider? image) async {
    if (image == null) {
      return null;
    }

    UploadTask uploadTask;

    if (image is FileImage) {
      final file = image.file;
      uploadTask = storageRef.child('$imageType.jpg').putFile(file);
    } else if (image is NetworkImage) {
      final url = image.url;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        uploadTask = storageRef.child('$imageType.jpg').putData(bytes);
      } else {
        throw Exception('Failed to load image');
      }
    } else {
      throw UnsupportedError('Unsupported image type');
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> _generateQrCodeImageUrl(
      String controlNumber, Reference storageRef) async {
    final qrValidationResult = QrValidator.validate(
      data: controlNumber,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        // ignore: deprecated_member_use
        color: const Color(0xFF000000), // QR color
        // ignore: deprecated_member_use
        emptyColor: Colors.blue[50], // Background color
        gapless: false,
      );
      final image = await painter.toImage(200);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      final fileName = 'qr_code_$controlNumber.png';
      final uploadTask = storageRef.child(fileName).putData(buffer);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } else {
      throw Exception('Failed to generate QR code');
    }
  }

  String generateControlNumber() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }
}
