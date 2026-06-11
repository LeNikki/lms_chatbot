import 'dart:convert';
import 'dart:io';
 import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lms_chatbot/app/app.dialogs.dart';
import 'package:lms_chatbot/app/app.locator.dart';
import 'package:lms_chatbot/app/app.router.dart';
import 'package:lms_chatbot/core/services/authservice.dart';
import 'package:lms_chatbot/core/services/constants/ApiConfigs.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

class HomeViewModel extends BaseViewModel {
  final TextEditingController messageController = TextEditingController();

  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthService>();
  final _dialogService = locator<DialogService>();

  // 🔥 USER DATA
  String role = "student";
  String name = "User";
  bool isAiTyping = false;

  // Sidebar state
  bool _showSidebar = false;
  bool get showSidebar => _showSidebar;

  // Chat messages
  List<Map<String, dynamic>> messages = [
    {'text': 'Hello! How can I help you today?', 'isUser': false},
  ];

  Color get primaryColor {
    return role == "teacher" ? Colors.blue : Colors.pink;
  }

  Color get backgroundColor {
    return role == "teacher" ? Colors.blue.shade50 : Colors.pink.shade50;
  }

  Color get drawerColor {
    return role == "teacher" ? Colors.blue.shade100 : Colors.pink.shade100;
  }

  // 🔥 INIT (MUST BE CALLED FROM VIEW)
  Future<void> init() async {
    setBusy(true);

    try {
      final userData = await _authService.getUserData();

      if (userData != null) {
        role = userData['role'] ?? "student";
        name = userData['name'] ?? "User";
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    }

    setBusy(false);
    notifyListeners();
  }

  void toggleSidebar() {
    _showSidebar = !_showSidebar;
    notifyListeners();
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    messages.add({
      'text': messageController.text.trim(),
      'isUser': true,
    });

    messageController.clear();
    notifyListeners();

    _mockAiResponse();
  }

  void logout() {
    _navigationService.navigateToLoginView();
  }

  

  Future<String> extractPdfText(File file) async {
  final bytes = await file.readAsBytes();

  final document = PdfDocument(inputBytes: bytes);

  final text = PdfTextExtractor(document).extractText();

  document.dispose();

  return text;
  }

    List<String> splitIntoChunks(
      String text, {
      int chunkSize = 1000,
    }) {
      List<String> chunks = [];

      for (int i = 0; i < text.length; i += chunkSize) {
        int end = i + chunkSize;

        if (end > text.length) {
          end = text.length;
        }

        chunks.add(text.substring(i, end));
      }

      return chunks;
    }

    Future<void> processPdfForKnowledgeBase() async {
        try {
          final result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );

          if (result == null || result.files.isEmpty) {
            return;
          }

          final path = result.files.single.path;

          if (path == null) {
            return;
          }

          final file = File(path);
          final fileName = result.files.single.name;

          // Extract text
          final text = await extractPdfText(file);

          if (text.trim().isEmpty) {
            throw Exception('No text found in PDF');
          }

          // Split text
          final chunks = splitIntoChunks(
            text,
            chunkSize: 1000,
          );

          // Save
          await saveKnowledgeChunks(
            fileName: fileName,
            chunks: chunks,
          );

          await _dialogService.showCustomDialog(
            variant: DialogType.infoAlert,
            title: 'Success',
            description:
                'PDF processed successfully. ${chunks.length} chunks saved.',
          );
        } catch (e) {
          await _dialogService.showCustomDialog(
            variant: DialogType.infoAlert,
            title: 'Error',
            description: e.toString(),
          );
        }
      }

    
    Future<void> saveKnowledgeChunks({
        required String fileName,
        required List<String> chunks,
      }) async {
        final firestore = FirebaseFirestore.instance;

        final batch = firestore.batch();

        for (int i = 0; i < chunks.length; i++) {
          final docRef = firestore.collection('knowledge_chunks').doc();

          batch.set(docRef, {
            'fileName': fileName,
            'chunkIndex': i,
            'content': chunks[i],
            'uploadedAt': FieldValue.serverTimestamp(),
            'chunkCount': chunks.length,
          });
        }

        await batch.commit();
      }

      Future<List<String>> getKnowledgeChunks() async {
        final snapshot = await FirebaseFirestore.instance
            .collection('knowledge_chunks')
            .orderBy('chunkIndex')
            .get();

        return snapshot.docs
            .map((e) => e['content'] as String)
            .toList();
      }

     Future<List<String>> searchKnowledgeChunks(String query) async {
        final snapshot = await FirebaseFirestore.instance
            .collection('knowledge_chunks')
            .get();

        final queryWords = query
            .toLowerCase()
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .split(RegExp(r'\s+'))
            .where((word) => word.length > 2)
            .toList();

        final scoredChunks = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          final content =
              (doc.data()['content'] ?? '').toString().toLowerCase();

          int score = 0;

          for (final word in queryWords) {
            if (content.contains(word)) {
              score++;
            }
          }

          if (score > 0) {
            scoredChunks.add({
              'score': score,
              'content': doc.data()['content'],
            });
          }
        }

        scoredChunks.sort(
          (a, b) => (b['score'] as int).compareTo(a['score'] as int),
        );

        return scoredChunks
            .take(5)
            .map((e) => e['content'].toString())
            .toList();
      }


      Future<void> _mockAiResponse() async {
       
          try {
            isAiTyping = true;
            notifyListeners();
            final question = messages.last['text'];

            final chunks = await searchKnowledgeChunks(question);

            final context = chunks.join('\n\n');

            final model = GenerativeModel(
              model: 'models/gemini-3.5-flash',
              apiKey: ApiConfigs.API_KEY,
            );

            final prompt = """
              -Answer the user's question using the provided context.
              -Be conversational and friendly but do not sound like a redundant robot, stop saying hi or hello unless it is the first of the conversation.
              -Also refer to previous conversation when answering.


              Context:
              $context

              Question:
              $question
              """;

            final response = await model.generateContent([
              Content.text(prompt),
            ]);

            messages.add({
              'text': response.text ?? 'No response.',
              'isUser': false,
            });

            notifyListeners();
          } catch (e) {
            messages.add({
              'text': 'Error: $e',
              'isUser': false,
            });

            notifyListeners();
          }
          isAiTyping = false;
          notifyListeners();
        }


    

    

//     Future<void> testGeminiHttp() async {
//   const apiKey = 'YOUR_NEW_KEY';

//   final response = await http.post(
//     Uri.parse(
//       'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
//     ),
//     headers: {
//       'Content-Type': 'application/json',
//     },
//     body: jsonEncode({
//       'contents': [
//         {
//           'parts': [
//             {'text': 'Hello'}
//           ]
//         }
//       ]
//     }),
//   );

//   print('STATUS: ${response.statusCode}');
//   print(response.body);
// }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
