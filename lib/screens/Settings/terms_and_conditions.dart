import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Tuntunin at Patakaran'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // IBP Logo at the top center
            Center(
              child: Image.asset(
                'assets/img/ibp_logo.png', // Replace with your actual logo asset path
                height: 100, // Adjust size as needed
              ),
            ),
            const SizedBox(height: 20), // Spacing between logo and content

            // Seksyon ng Patakaran sa Privacy
            _buildSectionHeader(
              'Patakaran sa Privacy para sa Philippine Electronic Legal Services and Access App',
            ),
            _buildSectionContent('Petsa ng Pagkakabisa: Oktubre 25, 2024'),
            _buildSectionContent(
              'Pinahahalagahan ng IBP Malolos Chapter ("kami") ang inyong privacy bilang mga gumagamit ng aming app ("ikaw"). Ipinapaliwanag ng Patakaran sa Privacy na ito kung paano namin kinokolekta, ginagamit, at pinoprotektahan ang iyong personal na impormasyon sa paggamit ng Philippine Electronic Legal Services and Access ("App").',
            ),
            _buildSectionHeader('1. Impormasyon na Kinokolekta Namin'),
            _buildSectionContent(
              'Maari naming kolektahin ang sumusunod na uri ng impormasyon:\n- Personal na Impormasyon: Pangalan, numero ng telepono, email address, at iba pang datos na kinakailangan sa pag-iskedyul ng appointment.\n- Detalye ng Appointment: Impormasyon kaugnay ng iyong konsultasyong legal at mga appointment.\n- Impormasyon ng Device: IP address, uri ng device, operating system, at iba pang teknikal na datos upang mapabuti ang performance ng App.',
            ),
            _buildSectionHeader(
                '2. Paano Namin Ginagamit ang Iyong Impormasyon'),
            _buildSectionContent(
              'Ginagamit namin ang nakolektang impormasyon para sa mga sumusunod na layunin:\n- Para sa pag-iskedyul at pamamahala ng mga appointment sa IBP Malolos Chapter.\n- Para makapagpadala ng paalala at mahahalagang anunsyo tungkol sa iyong appointment.\n- Para mapabuti ang seguridad at kakayahan ng App.\n- Para matupad ang mga legal na obligasyon.',
            ),
            _buildSectionHeader('3. Pagbabahagi ng Datos'),
            _buildSectionContent(
              'Hindi namin ibinebenta, inuupa, o ibinabahagi ang iyong personal na impormasyon sa iba maliban kung:\n- Iniaatas ng batas o ng legal na proseso.\n- Sa mga service provider na tumutulong sa operasyon ng App, sa ilalim ng mahigpit na kasunduan sa pagiging kompidensyal.',
            ),
            _buildSectionHeader('4. Seguridad ng Datos'),
            _buildSectionContent(
              'Gumagamit kami ng standard na mga hakbang sa seguridad upang protektahan ang iyong datos. Gayunpaman, walang pamamaraan ng pagpapadala o pagtatago sa internet na ganap na ligtas. Bagaman nagsusumikap kami, hindi namin magagarantiyahan ang absolutong seguridad.',
            ),
            _buildSectionHeader('5. Iyong mga Karapatan'),
            _buildSectionContent(
              'May karapatan kang:\n- Ma-access ang iyong personal na datos.\n- Humiling ng pagwawasto sa maling impormasyon.\n- Humiling ng pagbura ng datos, maliban kung ito ay hinihingi ng batas.\n- Tumanggi sa hindi mahalagang pagkuha ng datos.',
            ),
            _buildSectionHeader('6. Mga Pagbabago sa Patakaran sa Privacy'),
            _buildSectionContent(
              'Maaring baguhin ang Patakaran sa Privacy na ito paminsan-minsan. Ipapabatid namin sa iyo ang mahahalagang pagbabago sa pamamagitan ng App o email.',
            ),
            _buildSectionHeader('7. Makipag-ugnayan sa Amin'),
            _buildSectionContent(
              'Para sa mga tanong o alalahanin kaugnay ng iyong privacy, mangyaring makipag-ugnayan sa amin sa ibpbulacanchapter@gmail.com.',
            ),

            const SizedBox(height: 24),

// Seksyon ng Mga Tuntunin at Kundisyon
            _buildSectionHeader(
              'Mga Tuntunin at Kundisyon para sa Philippine Electronic Legal Services and Access App',
            ),
            _buildSectionContent('Petsa ng Pagkakabisa: Oktubre 25, 2024'),
            _buildSectionContent(
              'Ang Mga Tuntunin at Kundisyon na ito ay sumasaklaw sa paggamit ng Philippine Electronic Legal Services and Access ("App"). Sa paggamit ng App, ikaw ay sumasang-ayon na sumunod sa mga tuntuning ito.',
            ),
            _buildSectionHeader('1. Pagtanggap sa Mga Tuntunin'),
            _buildSectionContent(
              'Sa paggamit ng App, sumasang-ayon kang sundin ang mga Tuntunin na ito at lahat ng naaangkop na batas. Ang mga tuntuning ito ay bumubuo ng legal na kasunduan sa pagitan mo ("Gumagamit") at ng IBP Malolos Chapter ("Kami").',
            ),
            _buildSectionHeader('2. Paggamit ng App'),
            _buildSectionContent(
              'Maaari mong gamitin ang App para sa mga sumusunod:\n- Pag-iskedyul ng appointment sa IBP Malolos Chapter.\n- Pamamahala at pagtingin ng iyong mga detalye ng appointment.',
            ),
            _buildSectionHeader('3. Account ng Gumagamit'),
            _buildSectionContent(
              'Upang magamit ang ilang bahagi ng App, maaaring kailanganin mong gumawa ng account. Sumasang-ayon kang:\n- Magbigay ng tamang impormasyon sa pagrehistro.\n- Panatilihing napapanahon ang iyong impormasyon.\n- Panatilihing ligtas ang iyong login details.\n- Ipabatid kaagad sa amin kung may kahina-hinalang paggamit ng iyong account.',
            ),
            _buildSectionHeader(
                '4. Pag-iskedyul at Kanselasyon ng Appointment'),
            _buildSectionContent(
              'Ang mga appointment ay nakabatay sa availability. Bagama’t nagsusumikap kami sa pagbibigay ng tumpak na impormasyon, hindi namin magagarantiya ang availability ng tiyak na abogado o serbisyo.\n- Patakaran sa Kanselasyon: Maaari mong kanselahin o i-reschedule ang appointment sa pamamagitan ng App.',
            ),
            _buildSectionHeader('5. Karapatang Intelektwal'),
            _buildSectionContent(
              'Lahat ng nilalaman tulad ng teksto, larawan, logo, at software ay pagmamay-ari o lisensyado ng IBP Malolos Chapter at protektado sa ilalim ng batas ng karapatang intelektwal.',
            ),
            _buildSectionHeader('6. Privacy'),
            _buildSectionContent(
              'Ang paggamit mo ng App ay sakop din ng aming Patakaran sa Privacy. Sa paggamit ng App, sumasang-ayon kang mangolekta at gumamit kami ng impormasyon alinsunod sa patakarang iyon.',
            ),
            // Add more sections as necessary, using the same structure

            const SizedBox(height: 20), // Space before the website button

            // "Visit Our Website" button at the bottom
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF580049),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  // Add action here to navigate to the website
                },
                child: const Text(
                  'Visit Our Website',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
    );
  }
}
