import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
        title: const Text('About'),
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
        padding: const EdgeInsets.all(16.0), // Overall page padding
        child: ListView(
          children: [
            // IBP Logo
            Center(
              child: Image.asset(
                'assets/img/ibp_logo.png', // Replace with the correct path to your IBP logo image
                height: 100, // Adjust the size as needed
              ),
            ),
            const SizedBox(
                height: 20), // Space between the logo and the content
            // IBP Information Section
            _buildSectionHeader('About IBP'),
            _buildSectionContent(
              'The Integrated Bar of the Philippines (IBP) is the official organization of all lawyers in the Philippines, established by the Supreme Court in 1973. It was created to unify the legal profession, enhance professional standards, and improve access to justice across the country.',
            ),
            _buildSectionContent(
              'The IBP is recognized as a state-established body, with its formation backed by Republic Act No. 6397 and further strengthened by Presidential Decree No. 181.',
            ),
            const SizedBox(height: 24),
            // App Information Section
            _buildSectionHeader('About PH-ELSA App'),
            _buildSectionContent(
              'The PH-ELSA mobile application aims to address challenges in legal access, specifically within the IBP Malolos Chapter. It seeks to improve the appointment process, promote digitization, and make legal services more accessible and inclusive, ultimately enhancing the efficiency of the justice system.',
            ),
            const SizedBox(height: 24),
            // App Details Section
            _buildDetailRow('App Version:', '1.0.0'),
            _buildDetailRow('Developed by:', 'IBP Malolos Chapter'),
            const SizedBox(height: 32),
            // Visit Website Button Section
            _buildButtonSection(context),
          ],
        ),
      ),
    );
  }

  // Widget for the section header with IBP/App title style
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Color(0xFF580049), // Matches your color scheme
        ),
      ),
    );
  }

  // Widget for the section content, this keeps text inside proper spacing
  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.5, // Improves text readability
        ),
      ),
    );
  }

  // Widget for showing app version and developer details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for the Visit Website button at the end
  Widget _buildButtonSection(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF580049), // Custom button color
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: () {
          // Navigate to website if needed
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
    );
  }
}
