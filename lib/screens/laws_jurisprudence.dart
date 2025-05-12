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
                            'Maraming salamat sa paggamit ng aming aplikasyon, ang Philippine Electronic Legal Services and Access - Malolos Chapter (PH-ELSA Malolos), na nagbibigay ng serbisyo sa pag-book ng legal na konsultasyon sa pamamagitan ng aming appointment system. Bilang karagdagang serbisyo, nagbibigay rin kami ng access sa Jur.ph, isang AI-powered legal research platform sa Pilipinas.\n\n'
                            'Pakitandaan ang sumusunod na paalala at limitasyon ng pananagutan:\n\n'
                            '• Ang Jur.ph ay isang independiyenteng platform na hindi pagmamay-ari, pinapatakbo, o minementena ng PH-ELSA Malolos o ng Integrated Bar of the Philippines. Wala kaming kontrol, pag-verify, o pag-edit sa anumang nilalamang inilalathala sa Jur.ph.\n\n'
                            '• Lahat ng legal na materyales, teksto ng mga kaso, at impormasyong makukuha sa Jur.ph ay eksklusibong galing sa Jur.ph. Sila ang may buong responsibilidad at karapatan sa katumpakan at integridad ng kanilang nilalaman.\n\n'
                            '• Ang pagsasama ng Jur.ph sa aming app ay para lamang sa layuning pampagbibigay-impormasyon—upang mabigyan ang mga user ng madaling access sa legal na impormasyon. Ito ay hindi nangangahulugang pag-eendorso, pagbibigay ng legal na payo, o opisyal na representasyon.\n\n'
                            '• Hinihikayat ang lahat ng user na kumonsulta sa isang lisensyadong abogado para sa legal na payong angkop sa kanilang sitwasyon. Anumang pagtitiwala sa impormasyong galing sa Jur.ph ay nasa sariling desisyon at pananagutan ng user.\n\n'
                            '• Ang PH-ELSA Malolos at ang mga developer nito ay hindi mananagot sa anumang pagkawala, pinsala, o legal na epekto na maaaring idulot ng paggamit sa Jur.ph o interpretasyon ng nilalaman nito.',
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
