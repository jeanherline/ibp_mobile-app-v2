import 'package:flutter/material.dart';
import 'package:flutter_tawk/flutter_tawk.dart';

class CustomerSupportPage extends StatelessWidget {
  final String displayName;
  final String middleName;
  final String lastName;
  final String email;

  const CustomerSupportPage({
    super.key,
    required this.displayName,
    required this.middleName,
    required this.lastName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the required user information is loaded
    bool isUserDataLoaded = displayName.isNotEmpty && email.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Chat Support'),
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
      body: isUserDataLoaded
          ? Tawk(
              directChatLink:
                  'https://tawk.to/chat/666c61ce9a809f19fb3dc400/1i0bls3qi',
              visitor: TawkVisitor(
                name: '$displayName $middleName $lastName',
                email: email,
              ),
              onLoad: () {
                print('Tawk widget loaded');
              },
              onLinkTap: (String url) {
                print('Link tapped: $url');
              },
              placeholder: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : const Center(
              child:
                  CircularProgressIndicator(), // Show loading indicator while fetching data
            ),
    );
  }
}
