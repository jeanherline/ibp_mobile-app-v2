import 'dart:typed_data';
import 'package:ibp_app_ver2/screens/Konsulta/konsulta_submit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'barangay_certificate_of_indigency.dart';
import 'form_state_provider.dart';
import 'progress_bar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      userData = doc.data();
      isLoading = false;
    });
  }

  String? _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.month}/${dt.day}/${dt.year}';
    }
    return null;
  }

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildImageRow(String label, String? url, String? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date ?? 'Walang petsa ng upload',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        if (url != null && url.isNotEmpty)
          GestureDetector(
            onTap: () {
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
                        child: Image.network(url),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(url, height: 180),
            ),
          )
        else
          const Text(
            'Walang larawan na na-upload',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.redAccent,
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = context.watch<FormStateProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final uploadedImages = userData?['uploadedImages'] ?? {};

    return Scaffold(
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: CustomProgressBar(currentStep: 1, totalSteps: 3),
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pakitiyak na tama ang impormasyon.',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign
                              .center, // This centers the text inside the container
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                                '. Kung kailangan baguhin, pakibago muna sa iyong profile o sa nakaraang form para sa nature of legal assistance.',
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
                    const SizedBox(height: 30),
                    _buildGridItem('Pangalan', userData?['display_name'],
                        translation: 'Full Name'),
                    _buildGridItem('Araw ng Kapanganakan',
                        _formatTimestamp(userData?['dob']),
                        translation: 'Date of Birth'),
                    _buildGridItem('Tirahan', userData?['address'],
                        translation: 'Address'),
                    _buildGridItem('Lungsod', userData?['city'],
                        translation: 'City/Municipality'),
                    _buildGridItem('Numero ng Telepono', userData?['phone'],
                        translation: 'Contact Number'),
                    _buildGridItem('Kasarian', userData?['gender'],
                        translation: 'Gender'),
                    _buildGridItem('Pangalan ng Asawa', userData?['spouse'],
                        translation: 'Name of Spouse'),
                    _buildGridItem(
                        'Trabaho ng Asawa', userData?['spouseOccupation'],
                        translation: 'Occupation of Spouse'),
                    _buildGridItem(
                        'Mga Anak at Edad', userData?['childrenNamesAges'],
                        isMultiline: true, translation: 'Children and Age'),
                    _buildGridItem('Hanapbuhay', userData?['occupation'],
                        translation: 'Occupation'),
                    _buildGridItem(
                        'Klase ng Trabaho', userData?['kindOfEmployment'],
                        translation: 'Type of Employment'),
                    _buildGridItem(
                        'Pangalan ng Employer', userData?['employerName'],
                        translation: 'Employer Name'),
                    _buildGridItem(
                        'Tirahan ng Employer', userData?['employerAddress'],
                        translation: 'Employer Address'),
                    _buildGridItem('Buwanang Kita', userData?['monthlyIncome'],
                        isPeso: true, translation: 'Monthly Income'),
                    _buildGridItem(
                        'Uri ng Tulong Legal', formState.selectedAssistanceType,
                        translation: 'Type of Legal Assistance'),
                    _buildGridItem(
                      'Problema',
                      formState.problems,
                      isMultiline: true,
                      translation: 'Problem/s',
                    ),
                    _buildGridItem(
                      'Dahilan ng Problema',
                      formState.problemReason,
                      isMultiline: true,
                      translation: 'Reason for the Problem',
                    ),
                    _buildGridItem(
                      'Mga Solusyong Ninanais',
                      formState.desiredSolutions,
                      isMultiline: true,
                      translation: 'Desired Solution/s',
                    ),
                    _buildImageRow(
                      'Barangay Certificate (Barangay Certificate of Indigency)',
                      uploadedImages['barangayImageUrl'],
                      _formatTimestamp(
                          uploadedImages['barangayImageUrlDateUploaded']),
                    ),
                    _buildImageRow(
                      'DSWD Certificate (DSWD Certificate of Indigency)',
                      uploadedImages['dswdImageUrl'],
                      _formatTimestamp(
                          uploadedImages['dswdImageUrlDateUploaded']),
                    ),
                    _buildImageRow(
                      'PAO Disqualification (PAO Disqualification Letter)',
                      uploadedImages['paoImageUrl'],
                      _formatTimestamp(
                          uploadedImages['paoImageUrlDateUploaded']),
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
                    const SizedBox(height: 20),
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
                          final formState = context.read<FormStateProvider>();
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          try {
                            final controlNumber = _generateControlNumber();
                            formState.setControlNumber(controlNumber);
                            final docRef = FirebaseFirestore.instance
                                .collection('appointments')
                                .doc(controlNumber);
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();
                            final userData = userDoc.data() ?? {};

                            // Generate QR Code and upload
                            final qrBytes =
                                await _generateQrCode(controlNumber);
                            final qrRef = FirebaseStorage.instance
                                .ref('appt_qr_codes/$controlNumber.png');
                            final snapshot = await qrRef.putData(qrBytes);
                            final qrCodeUrl =
                                await snapshot.ref.getDownloadURL();

                            // Metadata
                            final loginActivity = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('loginActivity')
                                .orderBy('loginTime', descending: true)
                                .limit(1)
                                .get();
                            String ipAddress = 'Unknown';
                            String userAgent = 'Unknown';
                            if (loginActivity.docs.isNotEmpty) {
                              final meta = loginActivity.docs.first.data();
                              ipAddress = meta['ipAddress'] ?? 'Unknown';
                              userAgent = meta['deviceName'] ?? 'Unknown';
                            }

                            // Save to Firestore
                            await docRef.set({
                              'appointmentDetails': {
                                'uid': user.uid,
                                'appointmentStatus': 'pending',
                                'controlNumber': controlNumber,
                                'createdDate': FieldValue.serverTimestamp(),
                                'updatedTime': FieldValue.serverTimestamp(),
                                'read': 'false',
                                'qrCode': qrCodeUrl,
                                'apptType': 'Via App',
                              },
                              'legalAssistanceRequested': {
                                'selectedAssistanceType':
                                    formState.selectedAssistanceType,
                                'problems': formState.problems,
                                'problemReason': formState.problemReason,
                                'desiredSolutions': formState.desiredSolutions,
                              },
                            });

                            // Audit log
                            await FirebaseFirestore.instance
                                .collection('audit_logs')
                                .add({
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
                                  'newValue': qrCodeUrl
                                },
                              },
                              'affectedData': {
                                'targetUserId': user.uid,
                                'targetUserName': formState.fullName,
                              },
                              'metadata': {
                                'ipAddress': ipAddress,
                                'userAgent': userAgent,
                              },
                            });

                            // Notifications
                            await _sendNotification(
                              uid: user.uid,
                              message:
                                  'Your appointment request with Ticket Number $controlNumber has been submitted successfully. Please wait for the confirmation of the date and type of appointment.',
                              type: 'appointment',
                              controlNumber: controlNumber,
                            );

                            final headLawyers = await FirebaseFirestore.instance
                                .collection('users')
                                .where('member_type', isEqualTo: 'head')
                                .get();

                            for (final doc in headLawyers.docs) {
                              await _sendNotification(
                                uid: doc.id,
                                message:
                                    'A new appointment request has been submitted by ${formState.fullName} with Ticket Number $controlNumber and is awaiting your approval.',
                                type: 'appointment',
                                controlNumber: controlNumber,
                              );
                            }

                            // Close loading
                            if (context.mounted) Navigator.of(context).pop();

                            // Navigate and clear
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => KonsultaSubmit(
                                  controlNumber: controlNumber,
                                ),
                              ),
                            );
                            formState.clearFormState();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Form submitted successfully')),
                            );
                          } catch (e) {
                            if (context.mounted) Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to submit form: $e')),
                            );
                          }
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
                  ],
                ),
              ),
            ),
    );
  }
}

Widget _buildSectionCard(String title, List<Widget> children) {
  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

Widget _buildGridItem(String label, String? value,
    {bool isMultiline = false, bool isPeso = false, String? translation}) {
  final fullLabel = translation != null ? '$label (${translation})' : label;

  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: isPeso && value != null ? '₱ $value' : value ?? 'N/A',
          enabled: false,
          maxLines: isMultiline ? null : 1,
          minLines: isMultiline ? 3 : 1,
          style: const TextStyle(color: Colors.black, fontSize: 16),
          decoration: InputDecoration(
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black54),
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    ),
  );
}

Future<void> _saveSummaryForm(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final formStateProvider = context.read<FormStateProvider>();

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User is not authenticated')),
    );
    return;
  }

  final controlNumber = _generateControlNumber();
  formStateProvider.setControlNumber(controlNumber);

  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};

    final appointmentsRef = FirebaseFirestore.instance
        .collection('appointments')
        .doc(controlNumber);

    await appointmentsRef.set({
      'appointmentDetails': {
        'appointmentStatus': 'pending',
        'controlNumber': controlNumber,
        'newControlNumber': null,
        'newRequest': false,
        'requestReason': '',
        'appointmentDate': null,
        'apptType': 'Via App',
        'createdDate': FieldValue.serverTimestamp(),
        'qrCode': '', // optionally generate QR
        'apptRating': null,
        'refuseReason': '',
      },
      'legalAssistanceRequested': {
        'selectedAssistanceType': formStateProvider.selectedAssistanceType,
        'problems': formStateProvider.problems,
        'problemReason': formStateProvider.problemReason,
        'desiredSolutions': formStateProvider.desiredSolutions,
      },
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form submitted successfully')),
    );

    formStateProvider.clearFormState();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving form: $e')),
    );
  }
}

String _generateControlNumber() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
}

Future<Uint8List> _generateQrCode(String data) async {
  final qrValidationResult = QrValidator.validate(
    data: data,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.L,
  );

  if (qrValidationResult.status == QrValidationStatus.valid) {
    final painter = QrPainter.withQr(
      qr: qrValidationResult.qrCode!,
      gapless: false,
      dataModuleStyle: const QrDataModuleStyle(
        color: Colors.black,
        dataModuleShape: QrDataModuleShape.square,
      ),
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
    );

    final image = await painter.toImage(300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  } else {
    throw Exception('Invalid QR Code');
  }
}

Future<void> _sendNotification({
  required String uid,
  required String message,
  required String type,
  required String controlNumber,
}) async {
  final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
  await notifRef.set({
    'notifId': notifRef.id,
    'uid': uid,
    'message': message,
    'type': type,
    'read': false,
    'timestamp': FieldValue.serverTimestamp(),
    'controlNumber': controlNumber,
  });
}
