import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ibp_app_ver2/navbar.dart';
import 'package:ibp_app_ver2/screens/Appointments/appointmentDetails.dart';

class Appointments extends StatelessWidget {
  const Appointments({super.key, required int activeIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Appointments'),
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
      body: Stack(
        children: [
          const AppointmentsList(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const CustomNavigationBar(
                activeIndex: 1, // Ensure this shows the active home tab
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentsList extends StatefulWidget {
  const AppointmentsList({super.key});

  @override
  _AppointmentsListState createState() => _AppointmentsListState();
}

class _AppointmentsListState extends State<AppointmentsList> {
  @override
  void initState() {
    super.initState();
  }

  Icon getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icon(Icons.schedule, color: Colors.amber[800], size: 28);
      case 'approved':
        return Icon(Icons.task_alt, color: Colors.green[700], size: 28);
      case 'accepted':
        return Icon(Icons.how_to_reg, color: Colors.teal[700], size: 28);
      case 'scheduled':
        return const Icon(Icons.event_available,
            color: Color(0xFF580049), size: 28);
      case 'missed':
        return Icon(Icons.warning_amber, color: Colors.red[800], size: 28);
      case 'refused':
      case 'denied':
        return const Icon(Icons.remove_circle,
            color: Colors.redAccent, size: 28);
      case 'done':
        return Icon(Icons.check_circle, color: Colors.green[700], size: 28);
      default:
        return const Icon(Icons.calendar_today,
            color: Color(0xFF580049), size: 28);
    }
  }

  Stream<List<Map<String, dynamic>>> fetchAppointments() async* {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      yield [];
    } else {
      final userId = currentUser.uid;

      final appointmentsRef =
          FirebaseFirestore.instance.collection('appointments');

      final appointmentsSnapshot = appointmentsRef
          .where('uid', isEqualTo: userId)
          .orderBy('updatedTime', descending: true)
          .snapshots();

      await for (final snapshot in appointmentsSnapshot) {
        yield snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return const Center(child: Text('No appointments'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
                bottom: 80), // Adjust padding for bottom navigation bar
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final controlNumber =
                  appointment['appointmentDetails']['controlNumber'];
              final createdDate =
                  (appointment['createdDate'] as Timestamp).toDate();
              final updatedTime = appointment['updatedTime'] != null
                  ? (appointment['updatedTime'] as Timestamp).toDate()
                  : null;
              final rawStatus =
                  appointment['appointmentDetails']['appointmentStatus'];
              final appointmentStatus = capitalizeFirstLetter(
                  rawStatus == 'refused' ? 'approved' : rawStatus);
              final appointmentType =
                  appointment['appointmentDetails']['scheduleType'] ?? 'N/A';
              final appointmentDate =
                  appointment['appointmentDetails']['appointmentDate'] != null
                      ? (appointment['appointmentDetails']['appointmentDate']
                              as Timestamp)
                          .toDate()
                      : null;
              final readRaw = appointment['read'];
              final read = readRaw is bool ? readRaw : readRaw == 'true';

              bool isMissedAppointment() {
                if (appointmentDate != null && appointmentStatus != 'done') {
                  final now = DateTime.now();
                  return appointmentDate.isBefore(now);
                }
                return false;
              }

              return GestureDetector(
                onTap: () async {
                  // Mark the appointment as read
                  await FirebaseFirestore.instance
                      .collection('appointments')
                      .doc(controlNumber)
                      .update({'read': true});

                  // Update the UI after marking it as read
                  setState(() {
                    appointments[index]['read'] = true;
                  });

                  // Navigate to the appointment details page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetails(
                        controlNumber: controlNumber,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: read ? Colors.white : Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: read ? Colors.grey[300]! : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Conditionally show checkmark or calendar icon based on appointment status
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: getStatusIcon(appointmentStatus),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ticket number
                            Text(
                              'TICKET #$controlNumber',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            if (appointment['legalAssistanceRequested']
                                    ?['selectedAssistanceType'] !=
                                null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${appointment['legalAssistanceRequested']['selectedAssistanceType']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            if (appointment['appointmentDetails']
                                        ['appointmentStatus'] ==
                                    'denied' &&
                                appointment['clientEligibility']
                                        ?['denialReason'] !=
                                    null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: appointment['clientEligibility']
                                            ['denialReason'],
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (appointment['appointmentDetails']
                                        ['appointmentStatus'] ==
                                    'refused' &&
                                appointment['refusalHistory']?['reason'] !=
                                    null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  appointment['refusalHistory']['reason'],
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                            _buildEligibilityNote(appointment, rawStatus),

                            const SizedBox(height: 8),
                            // Status and appointment type block with background color
                            // If scheduled, show Appt. Schedule first
                            if (appointmentStatus.toLowerCase() ==
                                    'scheduled' &&
                                appointmentDate != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Appt. Schedule: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMMM dd, yyyy \'at\' hh:mm a')
                                          .format(appointmentDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

// Status and appointment type
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 12, 56, 122),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                appointmentStatus.toLowerCase() ==
                                        'pending_reschedule'
                                    ? 'Awaiting for Reschedule Approval'
                                    : capitalizeFirstLetter(
                                        appointmentType.isNotEmpty &&
                                                appointmentType != 'N/A'
                                            ? '$appointmentStatus — $appointmentType'
                                            : appointmentStatus,
                                      ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (appointment['appointmentDetails']
                                    ?['hasAdditionalDocs'] ==
                                'yes')
                              const Padding(
                                padding: EdgeInsets.only(top: 6.0),
                                child: Text(
                                  'Further documentation is needed. Please submit the requested files.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 8),

                            // Appointment Date or Reschedule Date
                            if (appointmentStatus.toLowerCase() !=
                                    'pending_reschedule' &&
                                appointmentDate != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (appointmentStatus.toLowerCase() ==
                                          'missed')
                                        const Text(
                                          'You have missed your appointment.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color.fromARGB(
                                                255, 166, 25, 15),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                    ],
                                  ),
                                ],
                              )
                            else if (appointment['rescheduleHistory'] != null &&
                                appointment['rescheduleHistory'] is List &&
                                (appointment['rescheduleHistory'] as List)
                                    .isNotEmpty &&
                                (appointment['rescheduleHistory'].last as Map<
                                        String, dynamic>)['rescheduleDate'] !=
                                    null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                    children: [
                                      const TextSpan(
                                        text: 'Request: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: DateFormat(
                                                'MMMM dd, yyyy \'at\' hh:mm a')
                                            .format(
                                          (appointment['rescheduleHistory']
                                                      .last['rescheduleDate']
                                                  as Timestamp)
                                              .toDate(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            // Created date
                            Text(
                              'Created: ${DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(createdDate)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (updatedTime != null)
                              Text(
                                'Last Updated: ${DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(updatedTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!read)
                        const Icon(
                          Icons.circle,
                          color: Colors.red,
                          size: 12, // Unread indicator size
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String capitalizeFirstLetter(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

void main() {
  runApp(const MaterialApp(
    home: Appointments(
      activeIndex: 1,
    ),
  ));
}

Widget _buildEligibilityNote(
    Map<String, dynamic> appointment, String rawStatus) {
  final notes =
      (appointment['clientEligibility']?['notes'] ?? '').toString().trim();

  if ([
    'scheduled',
    'approved',
    'accepted',
    'done',
    'missed',
    'refused',
    'denied'
  ].contains(rawStatus.toLowerCase())) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: RichText(
        textAlign: TextAlign.start,
        text: TextSpan(
          style: const TextStyle(fontSize: 14, height: 1.5),
          children: [
            TextSpan(
              text: notes.isNotEmpty ? notes : 'No further reason provided.',
              style: const TextStyle(
                color: Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return const SizedBox.shrink(); // No space if nothing to show
}
