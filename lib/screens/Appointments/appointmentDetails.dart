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
  int _selectedRating = 0; // Store selected rating
  bool _isJoiningMeeting = false;
  bool _isSubmittingRequest = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _fetchUserFullName(currentUser.uid);
    }
    _checkIfAppointmentAlreadyRequested();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _submitRating(int rating) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.controlNumber)
        .update({
      'rating': rating,
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text('Thank you for your feedback!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    setState(() {
      _selectedRating = rating; // Set permanent rating
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Salamat sa iyong rating!'),
        backgroundColor: Colors.green,
      ),
    );
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

  Future<void> _fetchUserFullName(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final userData = userDoc.data();
    final fullName = userData != null
        ? '${userData['display_name'] ?? ''} ${userData['middle_name'] ?? ''} ${userData['last_name'] ?? ''}'
            .trim()
        : 'Unknown User';

    print(fullName); // Or use it in your logic
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
      final rating = doc.data()?['rating']; // Fetch stored rating, if it exists

      // Update the state only if there's a change
      if (_hasRequestedNewAppointment != newRequest ||
          (rating != null && _selectedRating != rating)) {
        setState(() {
          _hasRequestedNewAppointment = newRequest;
          _selectedRating =
              rating ?? 0; // Set _selectedRating if a rating exists
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

  Future<void> joinMeeting(String controlNumber) async {
    setState(() {
      _isJoiningMeeting = true;
    });

    try {
      // Get the appointment document
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(controlNumber)
          .get();

      if (!appointmentDoc.exists) {
        print('Appointment not found.');
        return;
      }

      final appointmentData = appointmentDoc.data();
      final uid = appointmentData?['uid'];

      // Assuming new flattened structure

      if (uid == null || uid.isEmpty) {
        print('UID not found in appointment.');
        return;
      }

      // Fetch user data from users collection
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        print('User not found.');
        return;
      }

      final userData = userDoc.data();
      final fullName = [
        userData?['display_name'],
        userData?['middle_name'],
        userData?['last_name'],
        userData?['photoUrl || ""']
      ].where((name) => name != null && name.toString().isNotEmpty).join(' ');

      final email = userData?['email'] ?? 'guest@example.com';
      final photoUrl = userData?['photo_url'];

      // Generate JWT token
      final response = await http.get(
        Uri.parse(
          'https://us-central1-lawyer-app-ed056.cloudfunctions.net/api/generate-jwt?roomName=$controlNumber&isModerator=false',
        ),
      );

      if (response.statusCode != 200) {
        print('Failed to retrieve JWT: ${response.body}');
        return;
      }

      final jwtToken = jsonDecode(response.body)['token'];

      // Join Jitsi Meeting
      var options = JitsiMeetConferenceOptions(
        serverURL: "https://8x8.vc",
        room:
            "vpaas-magic-cookie-ef5ce88c523d41a599c8b1dc5b3ab765/$controlNumber",
        token: jwtToken,
        userInfo: JitsiMeetUserInfo(
          displayName: fullName,
          email: email,
          avatar: (photoUrl != null && photoUrl.startsWith('http'))
              ? photoUrl
              : null,
        ),
        configOverrides: {
          "startWithAudioMuted": true,
          "startWithVideoMuted": true,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "welcomepage.enabled": false,
          "invite.enabled": false,
          "meeting-password.enabled": false,
          "recording.enabled": false,
          "live-streaming.enabled": false,
          "video-share.enabled": false,
        },
      );
      print('🚀 Launching meeting with:');
      print('Room: ${options.room}');
      print('Token: ${options.token}');
      print(
          'User: ${options.userInfo?.displayName}, ${options.userInfo?.email}');

      await JitsiMeet().join(options);
      setState(() {
        _isJoiningMeeting = false;
      });
      print('Joined the meeting room: $controlNumber');
    } catch (e) {
      setState(() {
        _isJoiningMeeting = false;
      });
      print('Error joining the meeting: $e');
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
                final currentUserId =
                    FirebaseAuth.instance.currentUser?.uid ?? '';
                final history =
                    appointmentDetails['rescheduleHistory'] as List?;
                final userReschedules = history
                    ?.where(
                        (entry) => entry['rescheduledByUid'] == currentUserId)
                    .toList();
                final reschedulesLeft = 3 - (userReschedules?.length ?? 0);

                final qrCodeUrl =
                    appointmentDetails['appointmentDetails']['qrCode'];
                final rawStatus = appointmentDetails['appointmentDetails']
                    ['appointmentStatus'];
                final appointmentStatus =
                    rawStatus == 'refused' ? 'approved' : rawStatus;

                final scheduleType =
                    appointmentDetails['appointmentDetails']['scheduleType'];
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

                final userProfile = appointmentDetails['applicantProfile'];
                final userFullName =
                    userProfile != null && userProfile['fullName'] != null
                        ? userProfile['fullName']
                        : 'Guest User';

                final userEmail =
                    userProfile != null && userProfile['email'] != null
                        ? userProfile['email']
                        : 'guest@example.com';

                final userPhotoUrl =
                    userProfile != null ? userProfile['photo_url'] : null;

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
                    const SizedBox(height: 10),
                    if (appointmentStatus != 'done') ...[
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
                          () {
                            if (appointmentStatus == 'pending') {
                              return 'Ang inyong appointment ay kasalukuyang nasa pagsusuri. Mangyaring maghintay ng kumpirmasyon mula sa aming tanggapan.';
                            } else if (appointmentStatus == 'approved') {
                              return 'Naaprubahan ang inyong appointment. Mangyaring hintayin ang iskedyul ng konsultasyon.';
                            } else if (appointmentStatus == 'denied') {
                              return 'Paumanhin, hindi kayo kwalipikado para sa legal na tulong batay sa impormasyong inyong isinumite.';
                            } else if (appointmentStatus == 'accepted' ||
                                appointmentStatus == 'scheduled') {
                              return scheduleType == 'Online'
                                  ? 'Mangyaring hintayin ang kumpirmasyon ng petsa at oras ng inyong online na konsultasyon. Siguraduhing fully charged ang inyong device, may maayos na camera at mikropono, at stable na internet connection bago ang meeting. Kapag kumpirmado na, pindutin ang "Join Meeting" upang makapasok sa inyong konsultasyon.'
                                  : 'Mangyaring hintayin ang kumpirmasyon ng petsa at oras ng inyong in-person na konsultasyon. Siguraduhing dalhin ang printed na kopya ng inyong QR Code at lahat ng dokumentong in-upload sa app sa araw ng konsultasyon.';
                            } else if (appointmentStatus == 'missed') {
                              return 'Hindi kayo naka-attend sa inyong nakatakdang konsultasyon. Mangyaring makipag-ugnayan muli para sa muling pag-schedule.';
                            } else if (appointmentStatus == 'done') {
                              return 'Tapos na ang inyong konsultasyon. Lubos po kaming nagpapasalamat sa inyong tiwala. Nawa’y nakatulong kami sa inyong legal na pangangailangan.';
                            } else if (appointmentStatus ==
                                'pending_reschedule') {
                              return 'Natanggap na ang iyong kahilingan para sa bagong iskedyul. Mangyaring hintayin ang kumpirmasyon ng bagong appointment mula sa aming staff.';
                            } else {
                              return '';
                            }
                          }(),
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.black,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
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
                                appointmentStatus == 'pending_reschedule'
                                    ? 'Awaiting for Reschedule Approval'
                                    : scheduleType != null &&
                                            scheduleType.isNotEmpty
                                        ? capitalizeFirstLetter(
                                            '$appointmentStatus - $scheduleType')
                                        : capitalizeFirstLetter(
                                            appointmentStatus),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if ((appointmentStatus == 'denied' &&
                                    (appointmentDetails['clientEligibility']
                                                ?['denialReason'] !=
                                            null ||
                                        appointmentDetails['clientEligibility']
                                                ?['notes'] !=
                                            null)) ||
                                (appointmentStatus == 'approved' &&
                                    appointmentDetails['clientEligibility']
                                            ?['notes'] !=
                                        null))
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: appointmentStatus == 'denied'
                                      ? Colors.red[50]
                                      : Colors.green[50],
                                  border: Border.all(
                                    color: appointmentStatus == 'denied'
                                        ? Colors.redAccent.withOpacity(0.3)
                                        : Colors.green.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (appointmentStatus == 'denied' &&
                                        appointmentDetails['clientEligibility']
                                                ?['denialReason'] !=
                                            null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                                fontSize: 14, height: 1.5),
                                            children: [
                                              const TextSpan(
                                                text: 'Reason for Denial:\n',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.8,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              TextSpan(
                                                text: appointmentDetails[
                                                            'clientEligibility']
                                                        ?['denialReason'] ??
                                                    'N/A',
                                                style: const TextStyle(
                                                  color: Colors.redAccent,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (appointmentDetails['clientEligibility']
                                            ?['notes'] !=
                                        null)
                                      RichText(
                                        textAlign: TextAlign.start,
                                        text: TextSpan(
                                          style: const TextStyle(
                                              fontSize: 14, height: 1.5),
                                          children: [
                                            const TextSpan(
                                              text: 'Eligibility Notes:\n',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.8,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            TextSpan(
                                              text: appointmentDetails[
                                                          'clientEligibility']
                                                      ?['notes'] ??
                                                  'N/A',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (appointmentDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 18, color: Colors.blueGrey),
                                    const SizedBox(width: 8),
                                    Text(
                                      formatDate(appointmentDate),
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 5),
                            // Display the most recent reschedule reason
                            if (rescheduleHistory != null &&
                                rescheduleHistory.isNotEmpty &&
                                appointmentStatus != 'done')
                              Builder(
                                builder: (context) {
                                  final approvedHistory = rescheduleHistory
                                      .where((entry) =>
                                          entry['rescheduleStatus'] ==
                                          'approved')
                                      .toList()
                                    ..sort((a, b) =>
                                        (b['rescheduleTimestamp'] as Timestamp)
                                            .compareTo(a['rescheduleTimestamp']
                                                as Timestamp));

                                  if (approvedHistory.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final mostRecent = approvedHistory.first;
                                  final remainingHistory =
                                      approvedHistory.skip(1).toList();

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(
                                            top: 16.0, bottom: 8),
                                        child: Text(
                                          'Most Recent Reschedule',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      _buildRescheduleCard(mostRecent),
                                      if (remainingHistory.isNotEmpty)
                                        ExpansionTile(
                                          title: const Text(
                                            'View All Previous Reschedules',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          children: remainingHistory
                                              .map<Widget>((entry) =>
                                                  _buildRescheduleCard(entry))
                                              .toList(),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 10),
                            if (scheduleType == 'Online' &&
                                appointmentStatus != 'done' &&
                                appointmentStatus != 'missed') ...[
                              const SizedBox(height: 5),
                              ElevatedButton.icon(
                                onPressed: _isJoiningMeeting ||
                                        !(appointmentDate != null &&
                                            DateTime.now().toLocal().day ==
                                                appointmentDate
                                                    .toDate()
                                                    .toLocal()
                                                    .day &&
                                            DateTime.now().toLocal().month ==
                                                appointmentDate
                                                    .toDate()
                                                    .toLocal()
                                                    .month &&
                                            DateTime.now().toLocal().year ==
                                                appointmentDate
                                                    .toDate()
                                                    .toLocal()
                                                    .year)
                                    ? null
                                    : () => joinMeeting(widget.controlNumber),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 12, 122, 17),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: _isJoiningMeeting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.video_call,
                                        color: Colors.white),
                                label: Text(
                                  _isJoiningMeeting
                                      ? 'Joining...'
                                      : 'Join Meeting',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (appointmentStatus == 'missed')
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
                            const SizedBox(height: 20),

                            if (appointmentStatus == 'missed' ||
                                appointmentStatus == 'scheduled') ...[
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
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              ] else ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (userReschedules != null &&
                                        userReschedules.length >= 3) return;

                                    _showRequestForm(
                                        appointmentDetails, userFullName);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                        255, 240, 133, 11), // Orange color
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  label: Text(
                                    'Request Reschedule',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (userReschedules != null &&
                                    userReschedules.length < 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'You have $reschedulesLeft reschedule(s) left.',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Paalala: Maaari ka lamang magsumite ng hanggang tatlong (3) reschedule request. '
                                    'Kapag lumampas sa limit at hindi ka pa rin nakadalo, kailangan mong magsumite ng panibagong appointment request.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (appointmentStatus == 'done') ...[
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Rate your satisfaction with this appointment:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildStarRating(), // Display the rating stars
                                ],
                              ]
                            ],
                            if (appointmentStatus == 'done') ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Maraming salamat sa inyong pagtangkilik.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  'Paki-rate ang inyong karanasan sa konsultasyong ito:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _buildStarRating(),
                            ],
                            qrCodeUrl != null
                                ? Image.network(qrCodeUrl)
                                : const Center(
                                    child: Text('No QR code available.')),
                            const SizedBox(height: 30),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'APPOINTMENT DETAILS',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.event_note,
                                          size: 20, color: Colors.blueGrey),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black),
                                            children: [
                                              const TextSpan(
                                                text: 'Appointment Type: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: appointmentDetails[
                                                            'appointmentDetails']
                                                        ['apptType'] ??
                                                    'N/A',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.schedule,
                                          size: 20, color: Colors.blueGrey),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black),
                                            children: [
                                              const TextSpan(
                                                text: 'Schedule Type: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: appointmentDetails[
                                                            'appointmentDetails']
                                                        ['scheduleType'] ??
                                                    'N/A',
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

// --- Legal Assistance Info Card ---
                            if (appointmentDetails[
                                    'legalAssistanceRequested'] !=
                                null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'LEGAL ASSISTANCE INFO',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      icon: Icons.assignment_ind,
                                      title: 'Assistance Type: ',
                                      value: appointmentDetails[
                                              'legalAssistanceRequested']
                                          ['selectedAssistanceType'],
                                    ),
                                    _buildInfoRow(
                                      icon: Icons.report_problem,
                                      title: 'Problem/s: ',
                                      value: appointmentDetails[
                                              'legalAssistanceRequested']
                                          ['problems'],
                                    ),
                                    _buildInfoRow(
                                      icon: Icons.help_outline,
                                      title: 'Reason: ',
                                      value: appointmentDetails[
                                              'legalAssistanceRequested']
                                          ['problemReason'],
                                    ),
                                    _buildInfoRow(
                                      icon: Icons.lightbulb_outline,
                                      title: 'Desired Solution/s: ',
                                      value: appointmentDetails[
                                              'legalAssistanceRequested']
                                          ['desiredSolutions'],
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          iconSize: 40.0, // larger size
          icon: Icon(
            Icons.star,
            color:
                index < _selectedRating ? Colors.yellow[700] : Colors.grey[400],
          ),
          onPressed: _selectedRating == 0
              ? () => _submitRating(index + 1)
              : null, // Disable if already rated
          tooltip: _selectedRating == 0 ? 'I-rate ito' : 'Na-rate na',
        );
      }),
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
                        'Humiling ng Muling Pag-iskedyul',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        '(Request to Reschedule)',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(221, 42, 42, 42),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Ang form na ito ay para humiling ng bagong iskedyul para sa konsultasyon na hindi mo nadaluhan. Pakilagay ang dahilan kung bakit hindi ka naka-attend at ipahayag ang iyong kahilingan para sa muling pagtakda ng appointment.",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "(This form is to request a new schedule for the consultation you missed. Please explain why you were unable to attend and state your request for a rescheduled appointment.)",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color.fromARGB(221, 42, 42, 42),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        initialValue: _reason,
                        decoration: InputDecoration(
                          labelText: 'Dahilan ng Hindi Pagdalo...',
                          hintText:
                              'Halimbawa: Nagkasakit, may biglaang responsibilidad, etc.',
                          alignLabelWithHint: true,
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
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
                            return 'Pakilagay ang dahilan ng hindi pagdalo.';
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
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _selectFile();
                          setState(() {});
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
                          'Attach Supporting File (Optional)',
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
                          onPressed: _isSubmittingRequest
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    setState(() {
                                      _isSubmittingRequest = true;
                                    });
                                    Navigator.pop(context);
                                    await _requestAnotherAppointment(
                                        appointmentDetails);
                                    setState(() {
                                      _isSubmittingRequest = false;
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
                          child: _isSubmittingRequest
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Reschedule Request',
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
      Map<String, dynamic> appointmentDetails) async {
    final uid = appointmentDetails['uid'];

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    String? fileUrl;

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data();
      final fullName = userData != null
          ? '${userData['display_name'] ?? ''} ${userData['middle_name'] ?? ''} ${userData['last_name'] ?? ''}'
              .trim()
          : 'Unknown User';

      if (_selectedFile != null) {
        fileUrl = await _uploadFileToStorage(
            _selectedFile!, widget.controlNumber, fullName);
        if (fileUrl == null) throw Exception('Failed to upload file.');
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      final nowTimestamp = Timestamp.now();

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.controlNumber)
          .update({
        'appointmentDetails.appointmentStatus': 'pending_reschedule',
        'rescheduleHistory': FieldValue.arrayUnion([
          {
            'rescheduleReason': _reason,
            'rescheduleStatus': "pending",
            'rescheduleAppointmentType':
                appointmentDetails['appointmentDetails']['scheduleType'] ?? '',
            'rescheduleDate': appointmentDetails['appointmentDetails']
                ['appointmentDate'],
            'rescheduleTimestamp': nowTimestamp,
            'rescheduledByUid': currentUser?.uid ?? 'Unknown',
          }
        ]),
        'uploadedImages.newRequestUrl': fileUrl ?? '',
        'updatedTime': nowTimestamp,
      });

      await _sendNotification(
        uid: uid,
        message:
            'Your reschedule request for appointment (ID:${widget.controlNumber}) has been submitted.',
        type: 'appointment',
        controlNumber: widget.controlNumber,
      );

      // Notify the assigned lawyer
      final assignedLawyerId =
          appointmentDetails['appointmentDetails']['assignedLawyer'];

      if (assignedLawyerId != null && assignedLawyerId.toString().isNotEmpty) {
        await _sendNotification(
          uid: assignedLawyerId,
          message:
              '$fullName has submitted a reschedule request for appointment (ID:${widget.controlNumber}).',
          type: 'appointment',
          controlNumber: widget.controlNumber,
        );
      }

      setState(() {
        _hasRequestedNewAppointment = true;
        _isSubmitting = false;
      });

      await _showSuccessMessage();
    } catch (error) {
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

Widget _buildInfoRow({
  required IconData icon,
  required String title,
  required String? value,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14.0), // More space between rows
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.blueGrey),
        const SizedBox(width: 20), // Increased horizontal spacing
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 15, color: Colors.black),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value ?? 'N/A',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRescheduleCard(Map<String, dynamic> entry) {
  final date = entry['rescheduleDate'] != null
      ? (entry['rescheduleDate'] as Timestamp).toDate()
      : null;
  final timestamp = entry['rescheduleTimestamp'] != null
      ? (entry['rescheduleTimestamp'] as Timestamp).toDate()
      : null;
  final type = entry['rescheduleAppointmentType'] ?? 'N/A';
  final reason = entry['rescheduleReason'] ?? 'No reason provided';
  final statusRaw = entry['rescheduleStatus'] ?? 'N/A';
  final status = "${statusRaw[0].toUpperCase()}${statusRaw.substring(1)}";
  final uid = entry['rescheduledByUid'];

  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
    builder: (context, snapshot) {
      String name = 'Unknown User';

      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData &&
          snapshot.data!.exists) {
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        name =
            '${userData['display_name'] ?? ''} ${userData['middle_name'] ?? ''} ${userData['last_name'] ?? ''}'
                .trim();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (date != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Original Schedule: ${DateFormat('MMMM d, yyyy • h:mm a').format(date)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            Text(
              'Original Type: $type',
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reason:\n$reason',
              style: const TextStyle(
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            if (timestamp != null)
              Text(
                'Updated On: ${DateFormat('MMMM d, yyyy • h:mm a').format(timestamp)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Status: $status',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rescheduled By: $name',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    },
  );
}
