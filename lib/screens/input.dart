import 'package:flutter/material.dart';

import '../api_service.dart';

class MessageInputScreen extends StatefulWidget {
  final String userId;
  const MessageInputScreen({required this.userId, super.key});

  @override
  State<MessageInputScreen> createState() => _MessageInputScreenState();
}

class _MessageInputScreenState extends State<MessageInputScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    final apiService = ApiService();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a message."),
        ),
      );
      return;
    }

    // TODO: Process the message
//     final cleanText = TextPreprocessor.preprocess(message);
//
//     print("Cleaned Text: $cleanText");
//
// // Cheap rule-based filter
//     final filterResult = ActionableFilter.check(cleanText);
//
//     print(filterResult);
//
// // Stop immediately if definitely not actionable
//     if (!filterResult.isCandidate) {
//       print("Not actionable (filtered)");
//       return;
//     }
//
// // Candidate -> Ask LLM
//     final apiKey = "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" ;
//
//     final llmResult = await ActionabilityClassifier(apiKey).classify(cleanText);
//
//     print(llmResult);
//
//     if (!llmResult.actionable) {
//       print("Not actionable (filtered) by ai");
//       return;
//     }
//
//     final extractor = ExtractionService();
//
//     final record = await extractor.extract(
//       rawText: cleanText
//     );
//
//     print(record);
//
//     extractor.dispose();

    try {
      final result = await apiService.processMessage(
        userId: widget.userId,
        message: message,
        sender: "",
        source: "sms",
      );

      print(result);
    } catch (e) {
      print(e);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Message sent!"),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Message Input"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "Paste your email or SMS here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _sendMessage,
                child: const Text(
                  "Send",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}