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

  Stream<List<Map<String, dynamic>>> fetchAppointments() async* {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      yield [];
    } else {
      final userId = currentUser.uid;

      final appointmentsRef =
          FirebaseFirestore.instance.collection('appointments');

      final appointmentsSnapshot = appointmentsRef
          .where('applicantProfile.uid', isEqualTo: userId)
          .orderBy('appointmentDetails.createdDate', descending: true)
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
              final createdDate = (appointment['appointmentDetails']
                      ['createdDate'] as Timestamp)
                  .toDate();
              final appointmentStatus = capitalizeFirstLetter(
                  appointment['appointmentDetails']['appointmentStatus']);
              final appointmentType =
                  appointment['appointmentDetails']['apptType'] ?? 'N/A';
              final appointmentDate =
                  appointment['appointmentDetails']['appointmentDate'] != null
                      ? (appointment['appointmentDetails']['appointmentDate']
                              as Timestamp)
                          .toDate()
                      : null;
              final newRequest =
                  appointment['appointmentDetails']['newRequest'] ?? false;
              final read = appointment['read'] ?? false;

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
                        child: Icon(
                          appointmentStatus.toLowerCase() == 'done'
                              ? Icons.check_circle // Green check for done
                              : isMissedAppointment()
                                  ? Icons
                                      .cancel // Red cross for missed appointments
                                  : Icons
                                      .calendar_today, // Default calendar icon for other statuses
                          color: appointmentStatus.toLowerCase() == 'done'
                              ? const Color.fromARGB(
                                  255, 48, 133, 51) // Green color for done
                              : isMissedAppointment()
                                  ? const Color.fromARGB(255, 166, 25,
                                      15) // Red color for missed appointments
                                  : const Color(
                                      0xFF580049), // Purple for other statuses
                          size: 28, // Icon size
                        ),
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
                            const SizedBox(height: 8),
                            // Status and appointment type block with background color
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 12, 56, 122),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                capitalizeFirstLetter(
                                  appointmentType != null &&
                                          appointmentType.isNotEmpty &&
                                          appointmentType != 'N/A'
                                      ? '$appointmentStatus - $appointmentType'
                                      : appointmentStatus,
                                ),
                                style: const TextStyle(
                                  color: Colors.white, // White text
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Scheduled or Missed date
                            if (appointmentDate != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isMissedAppointment())
                                        const Text(
                                          'Missed: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color.fromARGB(255, 166, 25,
                                                15), // Red color for missed
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Scheduled: ', // Scheduled prefix
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors
                                                .black, // Black color for scheduled appointments
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      Text(
                                        DateFormat(
                                                'MMMM dd, yyyy \'at\' hh:mm a')
                                            .format(appointmentDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors
                                              .black, // Date remains black
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Add the new request message if applicable
                                  if (newRequest)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Text(
                                        'You have requested a new appt. for this',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color:
                                              Colors.black, // Grey italic text
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            // Created date
                            Text(
                              'Created: ${DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(createdDate)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors
                                    .grey, // Gray color for less prominence
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
