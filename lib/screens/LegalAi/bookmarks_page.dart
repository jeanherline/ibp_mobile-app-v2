import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookmarks',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF580049),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: uid == null
          ? const Center(child: Text('Walang user na naka-login.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('bookmarks')
                  .orderBy('bookmarkedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('Wala pang nai-save.'));
                }

                return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final content = data['content'] ?? '';
                      final timestamp = data['bookmarkedAt']?.toDate();
                      final formattedTime = timestamp != null
                          ? '${timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}'
                          : '';

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                content,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black87),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.grey),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .collection('bookmarks')
                                          .doc(docs[index].id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    });
              },
            ),
    );
  }
}
