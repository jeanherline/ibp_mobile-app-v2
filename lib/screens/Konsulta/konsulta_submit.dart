import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ibp_app_ver2/screens/Konsulta/progress_bar.dart';
import 'package:ibp_app_ver2/screens/home.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'form_state_provider.dart';

class KonsultaSubmit extends StatefulWidget {
  final String controlNumber;

  const KonsultaSubmit({super.key, required this.controlNumber});

  @override
  _KonsultaSubmitState createState() => _KonsultaSubmitState();
}

class _KonsultaSubmitState extends State<KonsultaSubmit> {
  Future<String?> _getQrCodeUrl(String controlNumber) async {
    final doc = await FirebaseFirestore.instance
        .collection('appointments')
        .where('appointmentDetails.controlNumber', isEqualTo: controlNumber)
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      return doc.docs.first.data()['appointmentDetails']['qrCode'];
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
    Provider.of<FormStateProvider>(context, listen: false).clearFormState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Provider.of<FormStateProvider>(context, listen: false)
                .clearFormState();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Home(
                  activeIndex: 0,
                ),
              ),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Isumite ang Suliraning Legal',
              style: TextStyle(
                color: Colors.black,
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.bold,
              ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: CustomProgressBar(currentStep: 2, totalSteps: 3),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Maraming Salamat!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PAALALA:',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Mangyaring hintayin ang kumpirmasyon ng petsa at oras ng inyong personal na pagkonsulta. Huwag kalimutang i-save ang QR Code at i-handa ang mga hard copy ng mga dokumentong ipinasa Via App sakaling maaprubahan ang inyong appointment.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '(Please wait for the confirmation of the date and type of consultation. Do not forget to save the QR Code and prepare the hard copies of the documents submitted Via App in case your appointment is approved.)',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 100,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'TICKET #${widget.controlNumber}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 12, 122, 17),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Pending Request',
                          style: TextStyle(
                            color: Colors.white, // White text
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'IBP Building, Provincial Capitol Malolos, Bulacan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FutureBuilder<String?>(
                        future: _getQrCodeUrl(widget.controlNumber),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Column(
                              children: [
                                SizedBox(height: 20),
                                CircularProgressIndicator(), // Show loading spinner
                                SizedBox(height: 10),
                                Text(
                                  'Loading QR Code...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return const Center(
                              child: Text('Error loading QR code.'),
                            );
                          } else if (snapshot.hasData) {
                            final qrCodeUrl = snapshot.data;
                            return qrCodeUrl != null
                                ? Image.network(qrCodeUrl)
                                : const Center(
                                    child: Text('No QR code available.'),
                                  );
                          } else {
                            return const Center(
                              child: Text('No QR code available.'),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
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
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
