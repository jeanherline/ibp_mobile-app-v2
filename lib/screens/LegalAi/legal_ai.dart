import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _controller.text = val.recognizedWords;
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> sendMessage(String userMessage) async {
    final timestamp = DateTime.now();

    setState(() {
      messages.add({
        'role': 'user',
        'content': userMessage,
        'timestamp': timestamp,
      });
      isLoading = true;
    });

    try {
      final response = await fetchOpenAiResponse(userMessage);
      setState(() {
        messages.add({
          'role': 'ai',
          'content': response,
          'timestamp': DateTime.now(),
        });
      });
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
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PH - ELSA',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF580049),
        iconTheme: const IconThemeData(color: Colors.white),
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
                            const SizedBox(height: 20),
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

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
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
                                      MediaQuery.of(context).size.width * 0.75,
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
                              Text(
                                formatTimestamp(msg['timestamp']),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
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
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
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
                  CircleAvatar(
                      backgroundColor: const Color(0xFF580049),
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                        ),
                        onPressed: _listen,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
