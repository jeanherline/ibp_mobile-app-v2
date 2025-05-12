import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ibp_app_ver2/screens/LegalAi/bookmarks_page.dart';
import 'package:ibp_app_ver2/screens/LegalAi/history_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LegalAi extends StatefulWidget {
  const LegalAi({super.key});

  @override
  State<LegalAi> createState() => _LegalAiState();
}

class _LegalAiState extends State<LegalAi> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';
  Set<String> bookmarkedMessages = {};
  final FlutterTts _flutterTts = FlutterTts();
  String? userPhotoUrl;
  final String defaultUserImage =
      'https://firebasestorage.googleapis.com/v0/b/lawyer-app-ed056.appspot.com/o/DefaultUserImage.jpg?alt=media&token=3ba45526-99d8-4d30-9cb5-505a5e23eda1';
  String? _speakingContent;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    loadBookmarks();
    loadTodayMessages();

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

  void loadTodayMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('chat_history')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp')
        .get();

    final todayMessages = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'role': data['role'],
        'content': data['content'],
        'timestamp': (data['timestamp'] as Timestamp).toDate(),
      };
    }).toList();

    setState(() {
      messages = todayMessages;
    });
  }

  void loadBookmarks() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .get();

      if (!mounted) return; // Prevent setState after dispose
      setState(() {
        bookmarkedMessages =
            snapshot.docs.map((doc) => doc['content'] as String).toSet();
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mic permission is required for voice input.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool hasSpeechPermission = await _speech.hasPermission;
      if (!hasSpeechPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech permission is not granted.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('Speech status: $val'),
        onError: (val) => debugPrint('Speech error: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        bool available = await _speech.initialize(
          onStatus: (val) {
            debugPrint('Speech status: $val');
            if (val == 'done' || val == 'notListening') {
              setState(() => _isListening = false);
              _speech.stop();
            }
          },
          onError: (val) {
            debugPrint('Speech error: $val');
            setState(() => _isListening = false);
          },
        );

        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) {
              String recognized = val.recognizedWords.trim();
              if (recognized.isNotEmpty) {
                recognized =
                    recognized[0].toUpperCase() + recognized.substring(1);
              }

              setState(() {
                _controller.text = recognized;
              });

              // Automatically stop when done speaking
              if (val.hasConfidenceRating && val.confidence > 0) {
                _speech.stop();
                setState(() => _isListening = false);
              }
            },

            localeId: 'en_PH', // English-Tagalog mix for Filipino speakers
            listenMode: stt.ListenMode.dictation,
          );
        }
      } else {
        debugPrint('Speech not available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> sendMessage(String userMessage) async {
    final timestamp = DateTime.now();

    // Add user message to UI
    setState(() {
      messages.add({
        'role': 'user',
        'content': userMessage,
        'timestamp': timestamp,
      });
      isLoading = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final uid = currentUser.uid;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      // Save user message to Firestore
      await userDoc.collection('chat_history').add({
        'role': 'user',
        'content': userMessage,
        'timestamp': timestamp,
      });
    }

    try {
      // Fetch AI response
      final response = await fetchOpenAiResponse(userMessage);

      // Add AI response to UI
      setState(() {
        messages.add({
          'role': 'ai',
          'content': response,
          'timestamp': DateTime.now(),
        });
      });

      // Save AI response to Firestore
      if (currentUser != null) {
        final uid = currentUser.uid;
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

        await userDoc.collection('chat_history').add({
          'role': 'ai',
          'content': response,
          'timestamp': DateTime.now(),
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          'role': 'ai',
          'content':
              '⚠️ Paumanhin, may problema sa pagkuha ng sagot. Subukang muli.',
          'timestamp': DateTime.now(),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to get response. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
      _controller.clear();
      FocusScope.of(context).unfocus();

      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String> fetchOpenAiResponse(String prompt) async {
    final uri = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are Elsa, a helpful legal assistant focused on Philippine laws, jurisprudence, and public legal concerns. Respond in the same language the user uses (Tagalog or English), and prioritize Philippine law."
          },
          {"role": "user", "content": prompt}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"].toString();
    } else {
      print("Error: ${response.statusCode} - ${response.body}");
      return "⚠️ Paumanhin, may problema sa pagkuha ng sagot. Subukang muli.";
    }
  }

  String formatTimestamp(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Elsa Legal AI',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF580049),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Read AI Disclaimer',
            onPressed: () => _showLegalAiDisclaimerModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Bookmarks',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarksPage()),
              );
              loadBookmarks(); // Reload to update the icon dynamically
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F4F7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/img/banner.png',
                              width: 500,
                            ),
                            const SizedBox(height: 16),
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF333333),
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(text: 'Kumusta! '),
                                  TextSpan(
                                    text: 'Ako si Elsa',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text:
                                        ', ang inyong AI Legal Assistant mula sa IBP Malolos.\n\nHanda akong tumulong sa iyong mga tanong tungkol sa batas ng Pilipinas.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isUser = msg['role'] == 'user';
                        final bool isBookmarked =
                            bookmarkedMessages.contains(msg['content']);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
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
                                    Text(
                                      isUser ? 'Ikaw' : 'Elsa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isUser
                                            ? const Color(0xFF580049)
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.75,
                                      ),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? const Color(0xFFEDE7F6)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(1, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        msg['content'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formatTimestamp(msg['timestamp']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        if (!isUser) ...[
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () async {
                                              final currentUser = FirebaseAuth
                                                  .instance.currentUser;
                                              if (currentUser == null) return;

                                              final uid = currentUser.uid;
                                              final userBookmarks =
                                                  FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(uid)
                                                      .collection('bookmarks');

                                              if (isBookmarked) {
                                                final existing =
                                                    await userBookmarks
                                                        .where(
                                                            'content',
                                                            isEqualTo:
                                                                msg['content'])
                                                        .limit(1)
                                                        .get();

                                                if (existing.docs.isNotEmpty) {
                                                  await userBookmarks
                                                      .doc(existing
                                                          .docs.first.id)
                                                      .delete();
                                                  setState(() {
                                                    bookmarkedMessages
                                                        .remove(msg['content']);
                                                  });
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Bookmark removed')),
                                                  );
                                                }
                                              } else {
                                                await userBookmarks.add({
                                                  'content': msg['content'],
                                                  'timestamp': msg['timestamp'],
                                                  'source': 'LegalAi',
                                                  'bookmarkedAt':
                                                      Timestamp.now(),
                                                });

                                                setState(() {
                                                  bookmarkedMessages
                                                      .add(msg['content']);
                                                });

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Response bookmarked!')),
                                                );
                                              }
                                            },
                                            child: Icon(
                                              isBookmarked
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              size: 20,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () async {
                                              if (_speakingContent ==
                                                  msg['content']) {
                                                await _flutterTts.stop();
                                                setState(() {
                                                  _speakingContent = null;
                                                });
                                              } else {
                                                await _flutterTts
                                                    .setLanguage("en-PH");
                                                await _flutterTts.setPitch(1.0);
                                                await _flutterTts
                                                    .setSpeechRate(0.45);
                                                await _flutterTts
                                                    .speak(msg['content']);
                                                setState(() {
                                                  _speakingContent =
                                                      msg['content'];
                                                });
                                              }
                                            },
                                            child: Icon(
                                              _speakingContent == msg['content']
                                                  ? Icons.stop
                                                  : Icons.volume_up,
                                              size: 20,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: msg['content']));
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
                                                size: 18, color: Colors.grey),
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
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 20),
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage('assets/img/ElsaProfile.png'),
                    ),
                    SizedBox(width: 10),
                    SpinKitThreeBounce(
                      color: Color(0xFF580049),
                      size: 18.0,
                    ),
                    SizedBox(width: 6),
                    Text("Elsa is typing...", style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 6, // Adjust as needed
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Magtanong tungkol sa batas...',
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            sendMessage(text.trim());
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF580049),
                        child: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                          ),
                          onPressed: _listen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (_isListening)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SpinKitRipple(
                                color: Color(0xFF580049),
                                size: 30.0,
                              ),
                              SizedBox(width: 10),
                            ],
                          ),
                        ),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF580049),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            final text = _controller.text.trim();
                            if (text.isNotEmpty) {
                              sendMessage(text);
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                fontSize: 14,
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
            '• Suportang Kasangkapan Lamang: Ang tampok na ito ay idinisenyo bilang karagdagang tulong para sa legal na pananaliksik at sanggunian. Hindi ito pamalit sa pormal na legal na serbisyo, edukasyon, o opisyal na legal na sanggunian.',
            style: TextStyle(fontSize: 14, height: 1.5),
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
}
