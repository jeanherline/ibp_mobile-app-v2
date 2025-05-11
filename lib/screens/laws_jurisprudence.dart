import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LawsJurisprudence extends StatefulWidget {
  const LawsJurisprudence({super.key});

  @override
  _LawsJurisprudenceState createState() => _LawsJurisprudenceState();
}

class _LawsJurisprudenceState extends State<LawsJurisprudence> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Laws & Jurisprudence'),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            tooltip: 'Read Disclaimer',
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jurisprudence.ph: AI-Powered Legal Research Platform',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Disclosure and Limitation of Liability',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    content: const SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text(
                            'Thank you for using our application, the Philippine Electronic Legal Services and Access - Malolos Chapter (PH-ELSA Malolos), which allows users to book legal consultations via our appointment system. As part of our services, we also provide access to Jur.ph, an AI-powered legal research platform in the Philippines.\n\n'
                            'Please be informed of the following disclosure and limitation of liability:\n\n'
                            '• Jur.ph is an independent platform not owned, operated, or maintained by PH-ELSA Malolos or the Integrated Bar of the Philippines. We do not modify, verify, or control the content published on Jur.ph.\n\n'
                            '• All legal materials, case texts, and information accessed through Jur.ph are provided solely by Jur.ph. They retain full ownership and responsibility for the accuracy and integrity of their content.\n\n'
                            '• The integration of Jur.ph into our app is purely for informational purposes—to offer users convenient access to legal resources. This does not constitute an endorsement, legal advice, or official representation.\n\n'
                            '• Users are strongly advised to consult with a licensed legal professional for legal guidance specific to their situation. Reliance on the information from Jur.ph is at your own discretion and risk.\n\n'
                            '• PH-ELSA Malolos and its developers disclaim any liability for loss, damages, or legal consequences arising from the use of Jur.ph or the interpretation of its content.',
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: const WebView(
        initialUrl: 'https://jur.ph/jurisprudence',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
