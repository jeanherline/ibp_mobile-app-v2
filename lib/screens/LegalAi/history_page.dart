import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? selectedDate;
  final FlutterTts _flutterTts = FlutterTts();
  Set<String> bookmarkedMessages = {};
  String? _speakingContent;

  String formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return DateFormat('MMM dd, h:mm a').format(dt);
  }

  String formatDateOnly(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  void loadBookmarks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .get();

      setState(() {
        bookmarkedMessages =
            snapshot.docs.map((doc) => doc['content'] as String).toSet();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadBookmarks();

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _speakingContent = null;
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        _speakingContent = null;
      });
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Chat History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF580049),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF4F4F7),
      body: uid == null
          ? const Center(child: Text('Walang user na naka-login.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('chat_history')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Wala pang kasaysayan.'));
                }

                // Get unique dates
                final dateMap = <String, List<QueryDocumentSnapshot>>{};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp?;
                  if (timestamp != null) {
                    final date = formatDateOnly(timestamp);
                    dateMap.putIfAbsent(date, () => []).add(doc);
                  }
                }

                if (selectedDate == null) {
                  // Show available dates
                  final sortedDates = dateMap.keys.toList()
                    ..sort((a, b) => b.compareTo(a));
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final dateStr = sortedDates[index];
                      final formatted = DateFormat('MMM dd, yyyy')
                          .format(DateTime.parse(dateStr));
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          title: Text(formatted),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            setState(() {
                              selectedDate = dateStr;
                            });
                          },
                        ),
                      );
                    },
                  );
                } else {
                  // Show messages for selected date
                  final messages = dateMap[selectedDate] ?? [];
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () =>
                                  setState(() => selectedDate = null),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(DateTime.parse(selectedDate!)),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final data =
                                messages[index].data() as Map<String, dynamic>;
                            final isUser = data['role'] == 'user';
                            final content = data['content'] ?? '';
                            final timestamp = data['timestamp'] as Timestamp?;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6), // Adds spacing between messages
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isUser)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundImage: AssetImage(
                                            'assets/img/ElsaProfile.png'),
                                      ),
                                    ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: isUser
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.75,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isUser
                                                ? const Color(0xFFE1D7F0)
                                                : Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft:
                                                  const Radius.circular(14),
                                              topRight:
                                                  const Radius.circular(14),
                                              bottomLeft: Radius.circular(
                                                  isUser ? 14 : 0),
                                              bottomRight: Radius.circular(
                                                  isUser ? 0 : 14),
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 2,
                                                offset: Offset(1, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(content,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              timestamp != null
                                                  ? formatTimestamp(timestamp)
                                                  : '',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600]),
                                            ),
                                            if (!isUser) ...[
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () async {
                                                  final uid = FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid;
                                                  if (uid == null) return;

                                                  final userBookmarks =
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(uid)
                                                          .collection(
                                                              'bookmarks');

                                                  final isBookmarked =
                                                      bookmarkedMessages
                                                          .contains(content);

                                                  if (isBookmarked) {
                                                    final snapshot =
                                                        await userBookmarks
                                                            .where('content',
                                                                isEqualTo:
                                                                    content)
                                                            .limit(1)
                                                            .get();
                                                    if (snapshot
                                                        .docs.isNotEmpty) {
                                                      await userBookmarks
                                                          .doc(snapshot
                                                              .docs.first.id)
                                                          .delete();
                                                      setState(() {
                                                        bookmarkedMessages
                                                            .remove(content);
                                                      });
                                                    }
                                                  } else {
                                                    await userBookmarks.add({
                                                      'content': content,
                                                      'timestamp': timestamp,
                                                      'source': 'HistoryPage',
                                                      'bookmarkedAt':
                                                          Timestamp.now(),
                                                    });
                                                    setState(() {
                                                      bookmarkedMessages
                                                          .add(content);
                                                    });
                                                  }
                                                },
                                                child: Icon(
                                                  bookmarkedMessages
                                                          .contains(content)
                                                      ? Icons.bookmark
                                                      : Icons.bookmark_border,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () async {
                                                  if (_speakingContent ==
                                                      content) {
                                                    await _flutterTts.stop();
                                                    setState(() {
                                                      _speakingContent = null;
                                                    });
                                                  } else {
                                                    await _flutterTts
                                                        .setLanguage("en-PH");
                                                    await _flutterTts
                                                        .setPitch(1.0);
                                                    await _flutterTts
                                                        .setSpeechRate(0.45);
                                                    await _flutterTts
                                                        .speak(content);
                                                    setState(() {
                                                      _speakingContent =
                                                          content;
                                                    });
                                                  }
                                                },
                                                child: Icon(
                                                  _speakingContent == content
                                                      ? Icons.stop
                                                      : Icons.volume_up,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(
                                                      ClipboardData(
                                                          text: content));
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Nakopya sa clipboard!'),
                                                      duration:
                                                          Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                                child: const Icon(Icons.copy,
                                                    size: 18,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
    );
  }
}
