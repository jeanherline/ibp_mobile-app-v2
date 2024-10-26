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
        title: const Text('Terms & Conditions and Privacy Policy'),
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

            // Privacy Policy Section
            _buildSectionHeader(
                'Privacy Policy for Philippine Electronic Legal Services and Access App'),
            _buildSectionContent('Effective Date: October 25, 2024'),
            _buildSectionContent(
              'The IBP Malolos Chapter ("we," "our," or "us") values the privacy of our users ("you" or "your"). This Privacy Policy explains how we collect, use, and protect your personal information when you use our Philippine Electronic Legal Services and Access ("App").',
            ),
            _buildSectionHeader('1. Information We Collect'),
            _buildSectionContent(
              'We may collect the following types of information:\n- Personal Identification Information: Name, phone number, email address, and other relevant data needed for appointment scheduling.\n- Appointment Details: Information related to your legal consultations and appointments.\n- Device Information: IP address, device type, operating system, and other technical data to improve the App’s performance.',
            ),
            _buildSectionHeader('2. How We Use Your Information'),
            _buildSectionContent(
              'We use the information collected for the following purposes:\n- To schedule and manage appointments with IBP Malolos Chapter members.\n- To communicate appointment reminders and other important updates.\n- To improve the functionality and security of the App.\n- To comply with legal obligations.',
            ),
            _buildSectionHeader('3. Data Sharing'),
            _buildSectionContent(
              'We do not share, sell, or rent your personal information to third parties, except:\n- When required by law or legal proceedings.\n- With service providers who help us operate the App, under strict confidentiality agreements.',
            ),
            _buildSectionHeader('4. Data Security'),
            _buildSectionContent(
              'We implement industry-standard security measures to protect your data. However, no method of transmission over the internet or electronic storage is completely secure. We cannot guarantee absolute security but strive to protect your information to the best of our ability.',
            ),
            _buildSectionHeader('5. Your Rights'),
            _buildSectionContent(
              'You have the right to:\n- Access your personal data.\n- Request corrections to inaccurate data.\n- Request deletion of your data, except when required by law.\n- Opt out of non-essential data collection.',
            ),
            _buildSectionHeader('6. Changes to This Privacy Policy'),
            _buildSectionContent(
              'We may update this Privacy Policy from time to time. You will be notified of any significant changes via the App or email.',
            ),
            _buildSectionHeader('7. Contact Us'),
            _buildSectionContent(
              'For questions or concerns regarding your privacy, please contact us at ibpbulacanchapter@gmail.com.',
            ),

            const SizedBox(height: 24), // Space before the next section

            // Terms and Conditions Section
            _buildSectionHeader(
                'Terms and Conditions for Philippine Electronic Legal Services and Access App'),
            _buildSectionContent('Effective Date: October 25, 2024'),
            _buildSectionContent(
              'These Terms and Conditions govern your use of the Philippine Electronic Legal Services and Access ("App"). By accessing or using the App, you agree to be bound by these Terms.',
            ),
            _buildSectionHeader('1. Acceptance of Terms'),
            _buildSectionContent(
              'By accessing the App, you agree to comply with these Terms and all applicable laws. These Terms form a legal agreement between you ("User") and the IBP Malolos Chapter ("We," "Us," or "Our").',
            ),
            _buildSectionHeader('2. Use of the App'),
            _buildSectionContent(
              'You may use the App for the following purposes:\n- Scheduling appointments with the IBP Malolos Chapter.\n- Managing and viewing your appointment details.',
            ),
            _buildSectionHeader('3. User Accounts'),
            _buildSectionContent(
              'To use certain features of the App, you may need to create an account. You agree to:\n- Provide accurate and complete information during registration.\n- Keep your account information up-to-date.\n- Maintain the confidentiality of your account login details.\n- Notify us immediately if you suspect unauthorized use of your account.',
            ),
            _buildSectionHeader('4. Appointment Scheduling and Cancellation'),
            _buildSectionContent(
              'Appointments scheduled through the App are subject to availability. While we strive to ensure accurate appointment information, we do not guarantee the availability of specific lawyers or services.\n- Cancellation Policy: You may cancel or reschedule appointments through the App.',
            ),
            _buildSectionHeader('5. Intellectual Property'),
            _buildSectionContent(
              'All content, including but not limited to text, images, logos, and software, is owned by or licensed to the IBP Malolos Chapter and is protected by copyright and other intellectual property laws.',
            ),
            _buildSectionHeader('6. Privacy'),
            _buildSectionContent(
              'Your use of the App is also governed by our Privacy Policy, which explains how we collect, use, and share your information. By using the App, you consent to the collection and use of your data in accordance with our Privacy Policy.',
            ),
            _buildSectionHeader('7. Service Availability'),
            _buildSectionContent(
              'While we aim to provide uninterrupted access to the App, we do not guarantee that it will always be available. The App may be subject to temporary outages, maintenance, or technical issues.',
            ),
            _buildSectionHeader('8. Termination'),
            _buildSectionContent(
              'We reserve the right to terminate or suspend your access to the App without notice if you violate these Terms or engage in prohibited activities.',
            ),
            _buildSectionHeader('9. Limitation of Liability'),
            _buildSectionContent(
              'To the extent permitted by law, the IBP Malolos Chapter shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App, including but not limited to data loss, service interruptions, or security breaches.',
            ),
            _buildSectionHeader('10. Indemnification'),
            _buildSectionContent(
              'You agree to indemnify and hold the IBP Malolos Chapter harmless from any claims, damages, or expenses arising out of your violation of these Terms or misuse of the App.',
            ),
            _buildSectionHeader('11. Governing Law'),
            _buildSectionContent(
              'These Terms are governed by the laws of the Philippines. Any disputes arising out of these Terms will be resolved in the courts of Bulacan, Philippines.',
            ),
            _buildSectionHeader('12. Changes to Terms'),
            _buildSectionContent(
              'We may modify these Terms at any time. Any changes will be posted within the App, and your continued use after such changes indicates your acceptance of the new Terms.',
            ),
            _buildSectionHeader('13. Contact Us'),
            _buildSectionContent(
              'If you have any questions regarding these Terms, please contact us at ibpbulacanchapter@gmail.com.',
            ),

            const SizedBox(height: 24), // Space before the next section

            // End-User License Agreement (EULA) Section
            _buildSectionHeader(
                'End-User License Agreement (EULA) for Philippine Electronic Legal Services and Access App'),
            _buildSectionContent('Effective Date: October 25, 2024'),
            _buildSectionContent(
              'This End-User License Agreement ("Agreement") is a legal contract between you ("User") and the IBP Malolos Chapter ("Licensor") regarding the use of the Philippine Electronic Legal Services and Access ("App"). By downloading or using the App, you agree to the terms of this Agreement.',
            ),
            _buildSectionHeader('1. License Grant'),
            _buildSectionContent(
              'The Licensor grants you a non-exclusive, non-transferable, revocable license to use the App solely for scheduling appointments with the IBP Malolos Chapter, in accordance with the terms of this Agreement.',
            ),
            _buildSectionHeader('2. Restrictions'),
            _buildSectionContent(
              'You agree not to:\n- Reverse engineer, decompile, or disassemble the App.\n- Modify or create derivative works based on the App.\n- Use the App for unlawful or unauthorized purposes.',
            ),
            _buildSectionHeader('3. User Data and Privacy'),
            _buildSectionContent(
              'By using the App, you agree to the collection and use of your personal information as outlined in the Privacy Policy.',
            ),

            const SizedBox(height: 24), // Space before the next section

            // Legal Compliance Section
            _buildSectionHeader(
                'Legal Compliance Statement for Philippine Electronic Legal Services and Access App'),
            _buildSectionContent('Effective Date: October 25, 2024'),
            _buildSectionContent(
              'We are committed to complying with all applicable laws and regulations in the operation of the App. This includes compliance with data privacy laws, intellectual property laws, and accessibility standards.',
            ),
            _buildSectionHeader('1. Compliance with Data Privacy Laws'),
            _buildSectionContent(
              'We comply with the Data Privacy Act of 2012 and other applicable privacy and data protection regulations to ensure the lawful collection, processing, storage, and sharing of personal data.',
            ),
            _buildSectionHeader(
                '2. Compliance with Record-Keeping Regulations'),
            _buildSectionContent(
              'We adhere to legal requirements for maintaining records of appointments and other relevant transactions, based on legal obligations and business needs.',
            ),
            _buildSectionHeader('3. Compliance with Accessibility Standards'),
            _buildSectionContent(
              'We strive to ensure the App is accessible to all users, including those with disabilities, by following relevant accessibility standards.',
            ),
            _buildSectionHeader(
                '4. Legal Requests and Disclosure of Information'),
            _buildSectionContent(
              'We may disclose user information to comply with legal obligations, such as court orders or requests from law enforcement agencies, in accordance with the Data Privacy Act.',
            ),
            _buildSectionHeader('5. User Rights Under the Law'),
            _buildSectionContent(
              'Users have the right to request access, rectification, or deletion of their personal data, subject to legal retention requirements.',
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
