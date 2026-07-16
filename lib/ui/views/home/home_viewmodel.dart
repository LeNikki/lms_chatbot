import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lms_chatbot/app/app.dialogs.dart';
import 'package:lms_chatbot/app/app.locator.dart';
import 'package:lms_chatbot/app/app.router.dart';
import 'package:lms_chatbot/core/models/knowledge_chunks.dart';
import 'package:lms_chatbot/core/services/authservice.dart';
import 'package:lms_chatbot/core/services/constants/ApiConfigs.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class HomeViewModel extends BaseViewModel {
  final TextEditingController messageController = TextEditingController();

  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthService>();
  final _dialogService = locator<DialogService>();
  late final GenerativeModel flashModel;
  late final GenerativeModel fallbackModel;
  List<KnowledgeChunk> _knowledgeCache = [];
  String uploadStatus = "";
  double uploadProgress = 0;

  // USER DATA
  String role = "student";
  String name = "User";
  bool isAiTyping = false;

  // Sidebar state
  bool _showSidebar = false;
  bool get showSidebar => _showSidebar;

  // Chat messages
  List<Map<String, dynamic>> messages = [
    {'text': 'Hello! Which topic should we learn today?', 'isUser': false},
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

  Future<void> init() async {
    setBusy(true);

    await loadKnowledgeBase();

    flashModel = GenerativeModel(
      model: 'models/gemini-3.5-flash',
      apiKey: ApiConfigs.API_KEY,
    );

    fallbackModel = GenerativeModel(
      model: 'models/gemini-2.5-flash',
      apiKey: ApiConfigs.API_KEY,
    );

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

  Future<void> loadKnowledgeBase() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('knowledge_chunks').get();

    _knowledgeCache = snapshot.docs.map((doc) {
      return KnowledgeChunk(
        content: doc['content'],
        chunkIndex: doc['chunkIndex'],
        fileName: doc['fileName'],
      );
    }).toList();
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

  Iterable<String> splitIntoChunks(
    String text, {
    int chunkSize = 1000,
  }) sync* {
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize > text.length) ? text.length : i + chunkSize;

      yield text.substring(i, end);
    }
  }

  Future<void> processPdfForKnowledgeBase() async {
    setBusy(true);

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      int successCount = 0;
      int failedCount = 0;
      int totalChunks = 0;

      for (int i = 0; i < result.files.length; i++) {
        final pickedFile = result.files[i];

        uploadStatus =
            "Uploading ${pickedFile.name}\n(${i + 1}/${result.files.length})";
        uploadProgress = (i + 1) / result.files.length;
        notifyListeners();

        try {
          final path = pickedFile.path;

          if (path == null) {
            failedCount++;
            continue;
          }

          final file = File(path);

          // Extract text
          final text = await extractPdfText(file);

          if (text.trim().isEmpty) {
            failedCount++;
            continue;
          }

          // Split into chunks (lazy)
          final chunks = splitIntoChunks(
            text,
            chunkSize: 1000,
          );

          // Upload chunks
          await saveKnowledgeChunks(
            fileName: pickedFile.name,
            chunks: chunks,
          );

          successCount++;
          totalChunks += (text.length / 1000).ceil();

          // Give Flutter a chance to repaint the UI
          await Future.delayed(Duration.zero);
        } catch (e) {
          debugPrint("Failed to process ${pickedFile.name}: $e");
          failedCount++;
        }
      }

      await _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Upload Complete',
        description: '$successCount PDF(s) uploaded successfully.\n'
            '$failedCount PDF(s) failed.\n\n'
            'Total chunks uploaded: $totalChunks',
      );
    } catch (e) {
      await _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Error',
        description: e.toString(),
      );
    } finally {
      uploadStatus = "";
      uploadProgress = 0;
      notifyListeners();
      setBusy(false);
    }
  }

  Future<void> saveKnowledgeChunks({
    required String fileName,
    required Iterable<String> chunks,
  }) async {
    final firestore = FirebaseFirestore.instance;

    const batchLimit = 400;

    WriteBatch batch = firestore.batch();

    int batchWrites = 0;
    int chunkIndex = 0;

    for (final chunk in chunks) {
      final docRef = firestore.collection('knowledge_chunks').doc();

      batch.set(docRef, {
        'fileName': fileName,
        'chunkIndex': chunkIndex,
        'content': chunk,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      _knowledgeCache.add(
        KnowledgeChunk(
          fileName: fileName,
          chunkIndex: chunkIndex,
          content: chunk,
        ),
      );

      batchWrites++;
      chunkIndex++;

      if (batchWrites == batchLimit) {
        await batch.commit();

        batch = firestore.batch();
        batchWrites = 0;
      }
    }

    if (batchWrites > 0) {
      await batch.commit();
    }
  }

  Future<List<String>> getKnowledgeChunks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('knowledge_chunks')
        .orderBy('chunkIndex')
        .get();

    return snapshot.docs.map((e) => e['content'] as String).toList();
  }

  Future<List<String>> searchKnowledgeChunks(String query) async {
    final queryWords = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((e) => e.length > 2)
        .toList();

    final scoredChunks = <Map<String, dynamic>>[];

    for (final chunk in _knowledgeCache) {
      int score = 0;

      final content = chunk.content.toLowerCase();

      for (final word in queryWords) {
        if (content.contains(word)) {
          score++;
        }
      }

      if (score > 0) {
        scoredChunks.add({
          'score': score,
          'content': chunk.content,
        });
      }
    }

    scoredChunks.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    return scoredChunks.take(5).map((e) => e['content'].toString()).toList();
  }

  Future<void> _mockAiResponse() async {
    try {
      isAiTyping = true;
      notifyListeners();
      final question = messages.last['text'];

      final chunks = await searchKnowledgeChunks(question);
      final knowledgeBase = chunks.join('\n\n');

      final prompt = """
      -Answer the user's question using the provided Knowledge Base.
      -Be conversational and friendly but do not sound like a redundant robot, stop saying hi or hello unless it is the first of the conversation.
      -Also refer to previous conversation when answering.
      -If the question is not found in Knowledge Base, just find the answer from the internet but inform the user first that you cannot find the answer from the provided knowledge base. 

      Context:
      $knowledgeBase

      Question:
      $question
      """;

      GenerateContentResponse response;

      try {
        response = await flashModel.generateContent([Content.text(prompt)]);
      } catch (apiError) {
        final errorMessage = apiError.toString();
        final is503 = errorMessage.contains('503') ||
            errorMessage.toLowerCase().contains('unavailable');

        if (is503) {
          await Future.delayed(const Duration(seconds: 2));

          response =
              await fallbackModel.generateContent([Content.text(prompt)]);
        } else {
          rethrow;
        }
      }

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
    } finally {
      isAiTyping = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
