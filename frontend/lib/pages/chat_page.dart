import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller =
      TextEditingController();

  // String answer = "";
  List<ChatMessage> messages = [];

  bool loading = false;

  Future<void> askAI() async {

    if (controller.text.trim().isEmpty) return;

    String question = controller.text;

    setState(() {
      messages.add(
        ChatMessage(
          text: question,
          isUser: true,
        ),
      );

      loading = true;
    });

    controller.clear();

    final result = await ChatService.sendQuestion(question);

    setState(() => loading = false);

    if (result.isError) {
      // Tampilkan Snackbar merah — jangan tambahkan ke chat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(result.text)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } else {
      // Sukses — tambahkan jawaban AI ke chat
      setState(() {
        messages.add(
          ChatMessage(
            text: result.text,
            isUser: false,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Panen Cerdas AI",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration:
                  const InputDecoration(
                hintText:
                    "Tulis pertanyaan...",
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: askAI,
              child: const Text(
                "Kirim",
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount:
                    messages.length +
                    (loading ? 1 : 0),
                itemBuilder: (context, index) {

                  if (loading &&
                      index == messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircularProgressIndicator(),
                        ],
                      ),
                    );
                  }

                  final msg = messages[index];

                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(
                        vertical: 6,
                      ),
                      padding:
                          const EdgeInsets.all(12),
                      constraints:
                          const BoxConstraints(
                        maxWidth: 600,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? Colors.green
                            : Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: msg.isUser
                          ? Text(
                              msg.text,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                              ),
                            )
                          : MarkdownBody(
                              data: msg.text,
                            ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}