import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ibp_app_ver2/screens/Appointments/appointments.dart';
import 'package:ibp_app_ver2/screens/Notifications/notifications.dart';
import 'package:ibp_app_ver2/screens/home.dart';
import 'package:ibp_app_ver2/screens/Profile/profile.dart';
import 'package:ibp_app_ver2/screens/LegalAi/legal_ai.dart';

class CustomNavigationBar extends StatefulWidget {
  final int activeIndex; // Accept activeIndex from parent screen

  const CustomNavigationBar({super.key, required this.activeIndex});

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox
          .shrink(); // Return an empty widget if no user is logged in
    }

    final userId = currentUser.uid;

    return Container(
      color: Colors.transparent, // Ensure full transparency
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Navigation Bar Background
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white, // navbar stays white
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: widget.activeIndex == 0
                        ? const Color.fromARGB(255, 79, 134, 216)
                        : const Color(0xFF580049),
                  ),
                  onPressed: () {
                    if (widget.activeIndex != 0) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const Home(activeIndex: 0),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.calendar_month,
                    color: widget.activeIndex == 1
                        ? const Color.fromARGB(255, 79, 134, 216)
                        : const Color(0xFF580049),
                  ),
                  onPressed: () {
                    if (widget.activeIndex != 1) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              const Appointments(activeIndex: 1),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 48), // space for the floating icon
                IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: widget.activeIndex == 2
                        ? const Color.fromARGB(255, 79, 134, 216)
                        : const Color(0xFF580049),
                  ),
                  onPressed: () {
                    if (widget.activeIndex != 2) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              const Notifications(activeIndex: 2),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: widget.activeIndex == 3
                        ? const Color.fromARGB(255, 79, 134, 216)
                        : const Color(0xFF580049),
                  ),
                  onPressed: () {
                    if (widget.activeIndex != 3) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const Profile(activeIndex: 3),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Floating Search Button
          Positioned(
            bottom: 30,
            child: GestureDetector(
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  final hasAccepted =
                      doc.data()?['legalAiDisclaimerAccepted'] ?? false;

                  if (hasAccepted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LegalAi()),
                    );
                  } else {
                    _showLegalAiDisclaimerModal(context);
                  }
                }
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF580049),
                  border: Border.all(
                    color: const Color.fromARGB(255, 45, 0, 40),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showLegalAiDisclaimerModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elsa AI Legal Assistant',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Disclosure and Limitation of Liability',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Ang Elsa AI Legal Assistant ay isang tampok ng Philippine Electronic Legal Services and Access (PH-ELSA) application sa ilalim ng Integrated Bar of the Philippines (IBP). Layunin nitong magbigay ng pangkalahatang impormasyon tungkol sa batas gaya ng jurisprudence, batas, at mahahalagang legal na prinsipyo. Gumagamit ito ng artificial intelligence upang bumuo ng mga sagot batay sa pampublikong legal na datos at input ng user. Paalala: ang mga impormasyong ibinibigay ng Elsa AI ay para lamang sa layuning pampagbibigay-kaalaman at hindi maituturing na legal na payo.\n\n'
            'Sa paggamit ng tampok na ito, sumasang-ayon ka sa mga sumusunod na kondisyon:\n\n'
            '• Walang Legal Advice o Attorney-Client Relationship: Ang AI Assistant na ito ay hindi nagbibigay ng legal na payo at hindi rin lumilikha ng attorney-client relationship. Ang mga sagot ay pawang impormasyon lamang at hindi dapat pagbatayan ng legal na desisyon nang walang propesyonal na konsultasyon.\n\n'
            '• Walang Garantiyang Katumpakan: Bagama’t layunin ng AI na magbigay ng tama at kapaki-pakinabang na impormasyon, maaaring hindi nito masaklaw ang pinakabagong legal na pagbabago o interpretasyon. Responsibilidad ng user na kumpirmahin ang lahat ng impormasyon.\n\n'
            '• Limitasyon ng Pananagutan: Ang IBP, mga developer, at mga kaugnay na partido ay hindi mananagot sa anumang pagkakamali, kakulangan, o epekto na dulot ng paggamit ng AI Assistant. Ginagamit mo ang tampok na ito nang may sariling pananagutan.\n\n'
            '• Responsibilidad ng User: Ikaw lamang ang may pananagutan sa kung paano mo ginagamit at binibigyang-kahulugan ang nilalamang binuo ng AI. Ang mga legal na desisyon ay dapat gawin kasama ng isang lisensyadong abogado.\n\n'
            '• Suportang Kasangkapan Lamang: Ang tampok na ito ay idinisenyo bilang karagdagang tulong para sa legal na pananaliksik at sanggunian. Hindi ito pamalit sa pormal na legal na serbisyo, edukasyon, o opisyal na legal na sanggunian.\n\n'
            'Sa pagpapatuloy, kinikilala mong nabasa, naunawaan, at tinatanggap mo ang paalalang ito at sumasang-ayon kang hindi managot ang IBP at mga kaugnay na partido sa anumang isyung maaaring lumitaw mula sa paggamit nito.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'I Understand',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'legalAiDisclaimerAccepted': true});
              }
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LegalAi()),
              );
            },
          ),
        ],
      );
    },
  );
}
