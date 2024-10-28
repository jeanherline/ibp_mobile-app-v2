import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // For file attachment
import 'dart:io';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart'; // For file handling

class AppointmentDetails extends StatefulWidget {
  final String controlNumber;

  const AppointmentDetails({super.key, required this.controlNumber});
  @override
  _AppointmentDetailsState createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {
  final _formKey = GlobalKey<FormState>();
  String _reason = '';
  File? _selectedFile; // To store the selected file
  bool _isSubmitting = false; // Track form submission
  String? _lastSubmittedAppointmentControlNumber; // Store last control number
  bool _hasRequestedNewAppointment =
      false; // Check if an appointment has already been requested

  @override
  void initState() {
    super.initState();
    _checkIfAppointmentAlreadyRequested();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _checkIfAppointmentAlreadyRequested() async {
    final appointmentDoc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.controlNumber)
        .get();

    if (appointmentDoc.exists &&
        appointmentDoc['appointmentDetails']['newRequest'] == true) {
      setState(() {
        _hasRequestedNewAppointment = true;
        _lastSubmittedAppointmentControlNumber = widget.controlNumber;
      });
    }
  }

  Future<void> _showSuccessMessage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment request submitted successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<Map<String, dynamic>?> fetchAppointmentDetails(
      String controlNumber) async {
    final doc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(controlNumber)
        .get();

    if (doc.exists) {
      final newRequest =
          doc.data()?['appointmentDetails']['newRequest'] ?? false;

      // Only update state if there's a change
      if (_hasRequestedNewAppointment != newRequest) {
        setState(() {
          _hasRequestedNewAppointment = newRequest;
        });
      }

      return doc.data();
    }
    return null;
  }

  String capitalizeFirstLetter(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String formatDate(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(dateTime);
  }

  Future<void> joinMeeting(String controlNumber, String fullName, String email,
      String? photoUrl) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://us-central1-lawyer-app-ed056.cloudfunctions.net/api/generate-jwt?roomName=$controlNumber&isModerator=false'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String jwtToken = data['token'];

        var options = JitsiMeetConferenceOptions(
          serverURL: "https://8x8.vc",
          room:
              'vpaas-magic-cookie-ef5ce88c523d41a599c8b1dc5b3ab765/$controlNumber',
          token: jwtToken,
          userInfo: JitsiMeetUserInfo(
            displayName: fullName.isNotEmpty ? fullName : "Guest",
            email: email.isNotEmpty ? email : "guest@example.com",
            avatar: photoUrl,
          ),
          configOverrides: {
            "startWithAudioMuted": true,
            "startWithVideoMuted": true,
          },
          featureFlags: {
            "unsaferoomwarning.enabled": false,
          },
        );

        await JitsiMeet().join(options);
        print('Joined the meeting room: $controlNumber');
      } else {
        print('Failed to retrieve JWT: ${response.body}');
      }
    } catch (error) {
      print('Error joining the meeting: $error');
    }
  }

  Future<void> _selectFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadFileToStorage(
      File file, String controlNumber, String fullName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("Error: User not authenticated.");
        return null;
      }
      // Rename the file to apptRequestFile
      final storageRef = FirebaseStorage.instance.ref().child(
          'konsulta_user_uploads/${user.uid}/$controlNumber/${fullName}_${controlNumber}_apptRequestFile');

      // Upload the file
      final uploadTask = storageRef.putFile(file);

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('File uploaded successfully. Download URL: $downloadUrl');
      return downloadUrl; // Return the URL of the uploaded file
    } catch (e) {
      // Provide a better user feedback on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _sendNotification({
    required String message,
    required String uid,
    required String type,
    required String controlNumber,
  }) async {
    final notificationDoc =
        FirebaseFirestore.instance.collection('notifications').doc();
    await notificationDoc.set({
      'notifId': notificationDoc.id,
      'uid': uid,
      'message': message,
      'type': type,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
      'controlNumber': controlNumber
    });
  }

  String generateControlNumber() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
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
        title: const Text('Appointment Details'),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: fetchAppointmentDetails(widget
                  .controlNumber), // Make sure this future doesn't get triggered continuously
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error loading appointment details.'));
                } else if (!snapshot.hasData) {
                  return const Center(
                      child: Text('No appointment details available.'));
                }

                final appointmentDetails = snapshot.data!;
                final qrCodeUrl =
                    appointmentDetails['appointmentDetails']['qrCode'];
                final appointmentStatus =
                    appointmentDetails['appointmentDetails']
                        ['appointmentStatus'];
                final appointmentType =
                    appointmentDetails['appointmentDetails']['apptType'];
                final appointmentDate =
                    appointmentDetails['appointmentDetails']['appointmentDate'];

                // Fetch rescheduleHistory and get the most recent reschedule reason
                final rescheduleHistory =
                    appointmentDetails['rescheduleHistory'] as List<dynamic>?;
                String? mostRecentRescheduleReason;

                if (rescheduleHistory != null && rescheduleHistory.isNotEmpty) {
                  final mostRecentReschedule =
                      rescheduleHistory.last as Map<String, dynamic>;
                  mostRecentRescheduleReason =
                      mostRecentReschedule['rescheduleReason'];
                }

                final userFullName = appointmentDetails['applicantProfile']
                        ['fullName'] ??
                    'Guest User';
                final userEmail = appointmentDetails['applicantProfile']
                        ['email'] ??
                    'guest@example.com';
                final userPhotoUrl =
                    appointmentDetails['applicantProfile']['photo_url'];

                final meetingPassword =
                    appointmentDetails['appointmentDetails']['meetingPass'];

                bool isMissedAppointment() {
                  final now = DateTime.now();
                  if (appointmentDate != null && appointmentStatus != 'done') {
                    return appointmentDate.toDate().isBefore(now);
                  }
                  return false;
                }

                final bool missed = isMissedAppointment();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (appointmentStatus != 'done') ...[
                      const SizedBox(height: 20),
                      const Text(
                        'PAALALA:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          appointmentType == 'Online'
                              ? 'Mangyaring hintayin ang kumpirmasyon ng petsa at oras ng inyong online na pagkonsulta. Siguraduhing handa ang iyong device at may stable na internet connection bago magsimula ang meeting. Pindutin ang "Join Meeting" kapag handa na upang makapasok sa online consultation.'
                              : 'Mangyaring hintayin ang kumpirmasyon ng petsa at oras ng inyong personal na pagkonsulta. Huwag kalimutang i-save ang QR Code at dalhin ang mga hard copy ng mga dokumentong ipinasa online sakaling maaprubahan ang inyong appointment.',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.black,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(25.0),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'TICKET #${widget.controlNumber}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 12, 56, 122),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                capitalizeFirstLetter(
                                  appointmentType != null &&
                                          appointmentType.isNotEmpty
                                      ? '$appointmentStatus - $appointmentType'
                                      : appointmentStatus,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (appointmentDate != null)
                              Text(
                                formatDate(appointmentDate),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 5),
                            // Display the most recent reschedule reason
                            if (mostRecentRescheduleReason != null &&
                                appointmentStatus != 'done')
                              Text(
                                mostRecentRescheduleReason,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const SizedBox(height: 15),
                            if (missed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'Missed Appointment',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 166, 25, 15),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            qrCodeUrl != null
                                ? Image.network(qrCodeUrl)
                                : const Center(
                                    child: Text('No QR code available.')),
                            const SizedBox(height: 20),
                            if (appointmentType == 'Online' &&
                                !missed &&
                                appointmentStatus != 'done') ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Password: $meetingPassword',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: Colors.blue),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: meetingPassword));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Meeting password copied to clipboard')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  joinMeeting(
                                    widget.controlNumber,
                                    userFullName,
                                    userEmail,
                                    userPhotoUrl,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 12, 122, 17),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.video_call,
                                    color: Colors.white),
                                label: Text(
                                  'Join Meeting',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (missed || appointmentStatus == 'done') ...[
                              const SizedBox(height: 10),
                              if (_hasRequestedNewAppointment) ...[
                                const Center(
                                  child: Text(
                                    'You have already requested another appointment for this.',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 166, 25, 15),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign
                                        .center, // Align text in the center
                                  ),
                                )
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _showRequestForm(
                                        appointmentDetails, userFullName);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255,
                                        12, 122, 17), // Active button color
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  label: Text(
                                    'Request Another Appointment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              ]
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRequestForm(
      Map<String, dynamic> appointmentDetails, String fullName) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 24.0,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Humiling ng Appointment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        '(Request a Follow-up Appointment)',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(221, 42, 42, 42),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Ang form na ito ay inilaan para humiling ng pangalawa o kasunod na appointment na may kaugnayan sa iyong naunang konsultasyon. Maaari kang humingi ng karagdagang tulong o ipagpatuloy ang talakayan hinggil sa parehong legal na usapin. Pakilagay ang dahilan ng iyong follow-up request.",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '(This form is intended to request a second or follow-up appointment related to your previous consultation. You can seek additional assistance or continue discussing the same legal matter. Please provide a reason for your follow-up request.)',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color.fromARGB(221, 42, 42, 42),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: _reason, // Retain text input
                        decoration: InputDecoration(
                          labelStyle: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pakilagay ang dahilan ng follow-up appointment.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _reason = value!;
                        },
                        onChanged: (value) {
                          setState(() {
                            _reason = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      // File attachment button
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _selectFile();
                          setState(
                              () {}); // Update the UI when file is attached
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blueAccent),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.attach_file,
                            color: Colors.blueAccent),
                        label: const Text(
                          'Attach File (Optional)',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'File Attached: ${_selectedFile!.path.split('/').last}',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 48, 133, 51),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              Navigator.pop(context); // Close the bottom sheet
                              await _requestAnotherAppointment(
                                  appointmentDetails, fullName);
                              // Reset values after successful submission
                              setState(() {
                                _selectedFile = null;
                                _reason = '';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF580049),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Submit Request',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _requestAnotherAppointment(
      Map<String, dynamic> appointmentDetails, String fullName) async {
    if (_isSubmitting) return; // Prevent multiple submissions

    setState(() {
      _isSubmitting = true;
    });

    String newControlNumber = generateControlNumber();
    String? fileUrl;

    try {
      // Fetch the most recent login activity data for metadata
      final loginActivitySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(appointmentDetails['applicantProfile']['uid'])
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

      // 1. Check if the user has selected a file and upload it first
      if (_selectedFile != null) {
        fileUrl = await _uploadFileToStorage(
            _selectedFile!, newControlNumber, fullName);

        if (fileUrl == null) {
          throw Exception('Failed to upload file.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully.')),
          );
        }
      }

      // 2. Update the current appointment to set newRequest to true with fileUrl if available
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.controlNumber)
          .update({
        'appointmentDetails.newRequest': true,
        'appointmentDetails.newControlNumber': newControlNumber,
        'appointmentDetails.requestReason': _reason,
        'uploadedImages.newRequestUrl': fileUrl ?? '', // Add the file URL here
      });

      // Audit log for updating current appointment
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'actionType': 'UPDATE',
        'timestamp': FieldValue.serverTimestamp(),
        'uid': appointmentDetails['applicantProfile']['uid'],
        'changes': {
          'appointmentDetails.newRequest': {
            'oldValue': false,
            'newValue': true
          },
          'appointmentDetails.newControlNumber': {
            'oldValue': widget.controlNumber,
            'newValue': newControlNumber,
          },
          'appointmentDetails.requestReason': {
            'oldValue': null,
            'newValue': _reason
          },
          'uploadedImages.newRequestUrl': {
            'oldValue': null,
            'newValue': fileUrl ?? ''
          },
        },
        'affectedData': {
          'targetUserId': appointmentDetails['applicantProfile']['uid'],
          'targetUserName': appointmentDetails['applicantProfile']['fullName'],
        },
        'metadata': {
          'ipAddress': ipAddress,
          'userAgent': userAgent,
        },
      });

      // 3. Generate QR code for the new appointment
      final qrCodeImageUrl = await _generateQrCodeImageUrl(newControlNumber);

      // 4. Create new appointment data with the uploaded file URL and QR code
      Map<String, dynamic> newAppointmentData = {
        'applicantProfile': {
          'uid': appointmentDetails['applicantProfile']['uid'],
          'fullName': appointmentDetails['applicantProfile']['fullName'],
          'dob': appointmentDetails['applicantProfile']['dob'],
          'address': appointmentDetails['applicantProfile']['address'],
          'city': appointmentDetails['applicantProfile']['city'],
          'contactNumber': appointmentDetails['applicantProfile']
              ['contactNumber'],
          'selectedGender': appointmentDetails['applicantProfile']
              ['selectedGender'],
          'spouseName': appointmentDetails['applicantProfile']['spouseName'],
          'spouseOccupation': appointmentDetails['applicantProfile']
              ['spouseOccupation'],
          'childrenNamesAges': appointmentDetails['applicantProfile']
              ['childrenNamesAges'],
        },
        'employmentProfile': {
          'occupation': appointmentDetails['employmentProfile']['occupation'],
          'kindOfEmployment': appointmentDetails['employmentProfile']
              ['kindOfEmployment'],
          'employerName': appointmentDetails['employmentProfile']
              ['employerName'],
          'employerAddress': appointmentDetails['employmentProfile']
              ['employerAddress'],
          'monthlyIncome': appointmentDetails['employmentProfile']
              ['monthlyIncome'],
        },
        'legalAssistanceRequested': {
          'selectedAssistanceType':
              appointmentDetails['legalAssistanceRequested']
                  ['selectedAssistanceType'],
          'problems': appointmentDetails['legalAssistanceRequested']
              ['problems'],
          'problemReason': appointmentDetails['legalAssistanceRequested']
              ['problemReason'],
          'desiredSolutions': appointmentDetails['legalAssistanceRequested']
              ['desiredSolutions'],
        },
        'uploadedImages': {
          'barangaySelectedImage': appointmentDetails['uploadedImages']
              ['barangaySelectedImage'],
          'dswdSelectedImage': appointmentDetails['uploadedImages']
              ['dswdSelectedImage'],
          'paoSelectedImage': appointmentDetails['uploadedImages']
              ['paoSelectedImage'],
        },
        'appointmentDetails': {
          'controlNumber': newControlNumber,
          'appointmentStatus': 'pending',
          'qrCode': qrCodeImageUrl,
          'createdDate': FieldValue.serverTimestamp(),
          'updatedTime': FieldValue.serverTimestamp(),
          'requestReason': _reason,
          'uploadedImages.newRequestUrl':
              fileUrl ?? '', // Add uploaded file URL here
        }
      };

      // 5. Save the new appointment to Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(newControlNumber)
          .set(newAppointmentData);

      // Audit log for creating a new appointment
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'actionType': 'CREATE',
        'timestamp': FieldValue.serverTimestamp(),
        'uid': appointmentDetails['applicantProfile']['uid'],
        'changes': {
          'appointmentDetails.controlNumber': {
            'oldValue': null,
            'newValue': newControlNumber
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
          'targetUserId': appointmentDetails['applicantProfile']['uid'],
          'targetUserName': appointmentDetails['applicantProfile']['fullName'],
        },
        'metadata': {
          'ipAddress': ipAddress,
          'userAgent': userAgent,
        },
      });

      // Notify the current user
      await _sendNotification(
        uid: appointmentDetails['applicantProfile']['uid'],
        message:
            'Your appointment request with Ticket Number $newControlNumber has been submitted successfully. Please wait for the confirmation of the date and type of appointment.',
        type: 'appointment',
        controlNumber: newControlNumber,
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
              'A new appointment request has been submitted by $fullName with Ticket Number $newControlNumber and is awaiting your approval.',
          type: 'appointment',
          controlNumber: newControlNumber,
        );
      }

      // Update state and UI
      setState(() {
        _hasRequestedNewAppointment = true;
        _lastSubmittedAppointmentControlNumber = newControlNumber;
        _isSubmitting = false;
      });

      // Show success message
      await _showSuccessMessage();
    } catch (error) {
      // Handle error and reset submitting state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<String> _generateQrCodeImageUrl(String controlNumber) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('appt_qr_codes/$controlNumber.png');

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
        color: const Color(0xFF000000), // QR code color (black)
        gapless: false,
      );

      final image = await painter.toImage(200); // Adjust size if needed
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final uploadTask = storageRef.putData(buffer);
      final snapshot = await uploadTask.whenComplete(() => {});

      // Get the download URL after uploading
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save the QR code URL to Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(controlNumber)
          .update({
        'appointmentDetails.qrCode': downloadUrl, // Save the QR code URL
      });

      return downloadUrl;
    } else {
      throw Exception('Failed to generate QR code');
    }
  }
}
