import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ibp_app_ver2/screens/chat_screen.dart';
import 'package:ibp_app_ver2/screens/laws_jurisprudence.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ibp_app_ver2/navbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ibp_app_ver2/screens/news_webview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key, required int activeIndex});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final PageController _pageController = PageController(initialPage: 0);
  String _firstName = '';
  String _displayName = '';
  String _middleName = '';
  String _lastName = '';
  String _email = '';
  String _userQrCode = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final cachedName = prefs.getString('display_name');
      final cachedQrCode = prefs.getString('user_qr_code');
      final cachedEmail = prefs.getString('email');
      final cachedMiddleName = prefs.getString('middle_name');
      final cachedLastName = prefs.getString('last_name');

      if (cachedName != null &&
          cachedQrCode != null &&
          cachedEmail != null &&
          cachedMiddleName != null &&
          cachedLastName != null) {
        setState(() {
          _firstName = cachedName;
          _displayName = cachedName;
          _userQrCode = cachedQrCode;
          _email = cachedEmail;
          _middleName = cachedMiddleName;
          _lastName = cachedLastName;
        });
      } else {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final displayName = userDoc['display_name'];
        final middleName = userDoc['middle_name'];
        final lastName = userDoc['last_name'];
        final email = userDoc['email'];
        final userQrCode = userDoc['userQrCode'];

        // Cache all values
        await prefs.setString('display_name', displayName);
        await prefs.setString('middle_name', middleName);
        await prefs.setString('last_name', lastName);
        await prefs.setString('email', email);
        await prefs.setString('user_qr_code', userQrCode);

        setState(() {
          _firstName = displayName;
          _displayName = displayName;
          _middleName = middleName;
          _lastName = lastName;
          _email = email;
          _userQrCode = userQrCode;
        });
      }
    }
  }

  void _showDisclaimerModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
            child: Text(
              'Maraming salamat sa paggamit ng aming aplikasyon, ang Philippine Electronic Legal Services and Access - Malolos Chapter (PH-ELSA Malolos), na nagbibigay ng serbisyo sa pag-book ng legal na konsultasyon sa pamamagitan ng aming appointment system. Bilang karagdagang serbisyo, nagbibigay rin kami ng access sa Jur.ph, isang AI-powered legal research platform sa Pilipinas.\n\n'
              'Pakitandaan ang sumusunod na paalala at limitasyon ng pananagutan:\n\n'
              '• Ang Jur.ph ay isang independiyenteng platform na hindi pagmamay-ari, pinapatakbo, o minementena ng PH-ELSA Malolos o ng Integrated Bar of the Philippines. Wala kaming kontrol, pag-verify, o pag-edit sa anumang nilalamang inilalathala sa Jur.ph.\n\n'
              '• Lahat ng legal na materyales, teksto ng mga kaso, at impormasyong makukuha sa Jur.ph ay eksklusibong galing sa Jur.ph. Sila ang may buong responsibilidad at karapatan sa katumpakan at integridad ng kanilang nilalaman.\n\n'
              '• Ang pagsasama ng Jur.ph sa aming app ay para lamang sa layuning pampagbibigay-impormasyon—upang mabigyan ang mga user ng madaling access sa legal na impormasyon. Ito ay hindi nangangahulugang pag-eendorso, pagbibigay ng legal na payo, o opisyal na representasyon.\n\n'
              '• Hinihikayat ang lahat ng user na kumonsulta sa isang lisensyadong abogado para sa legal na payong angkop sa kanilang sitwasyon. Anumang pagtitiwala sa impormasyong galing sa Jur.ph ay nasa sariling desisyon at pananagutan ng user.\n\n'
              '• Ang PH-ELSA Malolos at ang mga developer nito ay hindi mananagot sa anumang pagkawala, pinsala, o legal na epekto na maaaring idulot ng paggamit sa Jur.ph o interpretasyon ng nilalaman nito.\n\n'
              'Sa pagpapatuloy, kinikilala mong nabasa at naunawaan mo ang paalalang ito at sumasang-ayon kang magpatuloy ayon sa iyong sariling pagpapasya.',
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
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'jurDisclaimerAccepted': true});
                }

                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LawsJurisprudence()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showQrCodeModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(
              16.0), // Added more padding for better spacing
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _userQrCode.isNotEmpty
                          ? Image.network(_userQrCode)
                          : const Text('No QR code available.'),
                    ),
                    const SizedBox(
                        height:
                            20), // Increased space between the QR code and the text
                    const Text(
                      'This is your personal QR code.', // First line bold
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(
                            255, 0, 0, 0), // Lighter color for a softer tone
                        fontWeight: FontWeight.bold, // Bold for emphasis
                      ),
                    ),
                    const SizedBox(height: 5), // Space between two lines
                    const Text(
                      'Show this to the front desk when you walk into the IBP office.', // Second line
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5A5A5A), // Same lighter color
                        fontStyle: FontStyle.italic, // Italic style
                        fontWeight:
                            FontWeight.w400, // Light weight for soft tone
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIBPLogoModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(8.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Integrated Bar of the Philippines',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Gat Marcelo H. del Pilar (Bulacan Chapter)',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16.0),
                      child: Text(
                        'IBP Building, Provincial Capitol Compound,\nMalolos City, Bulacan\n\nTel. No: (044) 662 4786\nCel. No:+63 917 168 9873\nEmail: ibpbulacanchapter@gmail.com',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size to ensure responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF580049),
      appBar: AppBar(
        backgroundColor: const Color(0xFF580049),
        automaticallyImplyLeading: false,
        elevation: 0,
        leadingWidth: screenWidth * 0.4, // Responsive leading width
        leading: GestureDetector(
          onTap: () {
            _showQrCodeModal(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.white),
                SizedBox(width: screenWidth * 0.02), // Responsive spacing
                const Expanded(
                  child: Text(
                    'Personal QR',
                    style: TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/img/ibp_logo.png'),
            onPressed: () {
              _showIBPLogoModal(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.08,
                      10,
                      screenWidth * 0.08,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          'Magandang Araw, $_firstName',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                          maxLines: 1, // Adjust text size
                        ),
                        const AutoSizeText(
                          'Kumusta Ka?',
                          style: TextStyle(color: Colors.white, fontSize: 31),
                          maxLines: 1, // Adjust text size
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.25, // Adjust based on screen size
                    child: PageView(
                      controller: _pageController,
                      children: [
                        _buildPageItem(
                          title: '|  Legal na Tulong sa Isang Tap',
                          description:
                              'Ang PH-ELSA ay naglalayong gawing mas madali, mabilis, at accessible ang libreng serbisyong legal. Mula appointment request, anunsyo, AI assistance, chat support, hanggang video call consultation. Lahat ay nasa isang app para sa bawat Pilipino.',
                          color: const Color(0xFF221F1F),
                        ),
                        _buildPageItem(
                          title: '|  Konsultasyong Legal',
                          description:
                              'Ibahagi ang iyong problema sa batas at hintayin ang abiso mula sa IBP Malolos. Pwedeng walk-in o online ang consultation, depende sa assessment. Lahat ng ito ay pwedeng gawin gamit lang ang PH-ELSA app.',
                          color: const Color(0xFF4A148C),
                        ),
                        _buildPageItem(
                          title: '|  Maging kwalipikado',
                          description:
                              'I-upload ang Barangay at DSWD Certificates at PAO Disqualification Letter. Siguraduhing laging updated ang iyong mga dokumento upang manatiling valid ang iyong eligibility sa serbisyong legal.',
                          color: const Color(0xFF6A5ACD),
                        ),
                        _buildPageItem(
                          title: '|  Elsa: AI Legal Chat Assistant',
                          description:
                              'May tanong tungkol sa batas? Gamitin si Elsa, ang AI Legal Assistant ng PH-ELSA. Magtanong anumang oras at makatanggap ng legal information mula sa aming smart assistant na available 24/7.',
                          color: const Color(0xFF8B2E2E),
                        ),
                        _buildPageItem(
                          title: '|  Chat Support',
                          description:
                              'May concern sa appointment o dokumento? I-message agad ang IBP-Malolos staff gamit ang built-in chat. Sa PH-ELSA app, asahan ang mabilis at malinaw na tulong sa bawat hakbang ng proseso.',
                          color: const Color(0xFF00695C),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: 5,
                      effect: const ExpandingDotsEffect(
                        expansionFactor: 3,
                        spacing: 8,
                        radius: 16,
                        dotWidth: 16,
                        dotHeight: 8,
                        dotColor: Color(0xFFC0E0FF),
                        activeDotColor: Color(0xFFD8C54F),
                        paintStyle: PaintingStyle.fill,
                      ),
                      onDotClicked: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIconOption(
                              icon: Icons.gavel_rounded,
                              label: 'Konsulta',
                              onTap: () async {
                                User? user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  final userDoc = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .get();

                                  final data = userDoc.data();
                                  final phone = data?['phone'] ?? '';
                                  final spouse = data?['spouse'] ?? '';
                                  final spouseOccupation =
                                      data?['spouseOccupation'] ?? '';
                                  final maritalStatus =
                                      data?['maritalStatus'] ?? '';
                                  final uploadedImages =
                                      data?['uploadedImages'] ?? {};

                                  final barangayImageUrl =
                                      uploadedImages['barangayImageUrl'] ?? '';
                                  final dswdImageUrl =
                                      uploadedImages['dswdImageUrl'] ?? '';
                                  final paoImageUrl =
                                      uploadedImages['paoImageUrl'] ?? '';

                                  final barangayDate = uploadedImages[
                                          'barangayImageUrlDateUploaded']
                                      ?.toDate();
                                  final dswdDate =
                                      uploadedImages['dswdImageUrlDateUploaded']
                                          ?.toDate();
                                  final paoDate =
                                      uploadedImages['paoImageUrlDateUploaded']
                                          ?.toDate();

                                  final now = DateTime.now();
                                  final sixMonthsAgo =
                                      now.subtract(const Duration(days: 180));

                                  final isBarangayExpired =
                                      barangayDate == null ||
                                          barangayDate.isBefore(sixMonthsAgo);
                                  final isDswdExpired = dswdDate == null ||
                                      dswdDate.isBefore(sixMonthsAgo);
                                  final isPaoExpired = paoDate == null ||
                                      paoDate.isBefore(sixMonthsAgo);

                                  final address = data?['address'] ?? '';
                                  final childrenNamesAges =
                                      data?['childrenNamesAges'] ?? '';
                                  final profileIncomplete = phone.isEmpty ||
                                      address.isEmpty || // ✅ always required
                                      (maritalStatus != 'Single' &&
                                          (spouse.isEmpty ||
                                              spouseOccupation.isEmpty ||
                                              childrenNamesAges
                                                  .isEmpty // ✅ required if not single
                                          )) ||
                                      (data?['occupation'] ?? '').isEmpty ||
                                      (data?['employerName'] ?? '').isEmpty ||
                                      (data?['employerAddress'] ?? '')
                                          .isEmpty ||
                                      (data?['monthlyIncome'] ?? '').isEmpty ||
                                      (data?['employmentType'] == null ||
                                          data?['employmentType'] ==
                                              'Select') ||
                                      (data?['city'] == null ||
                                          data?['city'] == 'Select') ||
                                      barangayImageUrl.isEmpty ||
                                      dswdImageUrl.isEmpty ||
                                      paoImageUrl.isEmpty ||
                                      isBarangayExpired ||
                                      isDswdExpired ||
                                      isPaoExpired;

                                  if (profileIncomplete) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text(
                                              'I-update ang Profile'),
                                          content: const Text(
                                            'Tiyakin na kumpleto ang iyong profile kabilang ang address, pangalan at edad ng mga anak (kung hindi single) at ang lahat ng kinakailangang dokumento mula sa Barangay, DSWD at PAO bago magsumite ng request.',
                                          ),
                                          actions: [
                                            TextButton(
                                              child:
                                                  const Text('Ayusin Ngayon'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.pushNamed(
                                                    context, '/edit_profile');
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    Navigator.pushNamed(context,
                                        '/nature_of_legal_assistance_requested');
                                  }
                                }
                              },
                            ),
                            _buildIconOption(
                              icon: FontAwesomeIcons.landmark,
                              label: 'Batas',
                              onTap: () async {
                                User? user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  final userDoc = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .get();

                                  final hasAccepted = userDoc
                                          .data()?['jurDisclaimerAccepted'] ??
                                      false;

                                  if (hasAccepted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LawsJurisprudence()),
                                    );
                                  } else {
                                    _showDisclaimerModal(context);
                                  }
                                }
                              },
                            ),
                            _buildIconOption(
                              icon: FontAwesomeIcons.solidNewspaper,
                              label: 'Pahayagan',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const NewsWebView()),
                                );
                              },
                            ),
                            _buildIconOption(
                              icon: FontAwesomeIcons.headset,
                              label: 'Tanong',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerSupportPage(
                                      displayName: _displayName,
                                      middleName: _middleName,
                                      lastName: _lastName,
                                      email: _email,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mga Madalas Itanong (FAQs)',
                                style: TextStyle(
                                  color: Color(0xFF580049),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildFAQItem(
                          question:
                              'Ano ang Integrated Bar of the Philippines?',
                          answer:
                              'Ang Integrated Bar of the Philippines (IBP) ay ang pambansang organisasyon ng mga abogado sa Pilipinas. Ito ang opisyal na asosasyon ng lahat ng mga abugado sa bansa at nasa ilalim ng superbisyon ng Korte Suprema ng Pilipinas.',
                        ),
                        _buildFAQItem(
                          question: 'Saan matatagpuan ang IBP Malolos?',
                          answer:
                              'Ang opisina ng IBP Gat Marcelo H. Del Pilar Bulacan Chapter ay matatagpuan sa ‘VR68+7C5, New IBP Bulacan Office, Capitolio Road, City of Malolos, 3000 Bulacan’.',
                        ),
                        _buildFAQItem(
                          question: 'Tuwing kailan bukas ang IBP Malolos?',
                          answer:
                              'Bukas ang IBP Malolos mula Lunes hanggang Sabado mula 9:00 AM hanggang 5:00 PM. Ngunit ang Legal Aid Office nila ay bukas lamang tuwing Martes at Huwebes mula 1:00 PM hanggang 5:00 PM.',
                        ),
                        _buildFAQItem(
                          question:
                              'Ano ang mga requirements para sa Legal Aid?',
                          answer:
                              'Para makapagsumite ng appointment gamit ang app, mangyaring ihanda ang iyong Certificate of Indigency mula sa Barangay ninyo, Certificate of Indigency mula sa DSWD, at Disqualification Letter mula sa PAO.',
                        ),
                        _buildFAQItem(
                          question:
                              'Ano ang mga klase ng tulong legal na aking maaaring hingin?',
                          answer:
                              'Maaari kang humingi ng tulong mula sa IBP Bulacan Chapter para sa Payong Legal (Legal Advice), Legal na Representasyon (Legal Representation), o tulong para sa paggawa ng Legal na Dokumento (Drafting of Legal Document).',
                        ),
                        _buildFAQItem(
                          question:
                              'Paano ko puwedeng makontak ang IBP Malolos?',
                          answer:
                              'Maaari kang tumawag sa kanilang telepono (044) 662 4786 o sa cellphone number +63 917 168 9873 kung sakaling ikaw ay may ibang katanungan. Maaari ka ring magtanong tungkol sa appointment at sa IBP Malolos gamit ang Chat Inquiries feature ng aming app.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                      height: 50), // Add some space above the navigation bar
                ],
              ),
            ),
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
                  activeIndex: 0, // Ensure this shows the active home tab
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageItem({
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildIconOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF580049),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(answer,
              style: const TextStyle(
                  color: Color.fromARGB(255, 54, 54, 54), fontSize: 14)),
        ],
      ),
    );
  }
}
