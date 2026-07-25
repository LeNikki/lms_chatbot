import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lms_chatbot/app/app.dialogs.dart';
import 'package:lms_chatbot/app/app.locator.dart';
import 'package:lms_chatbot/app/app.router.dart';
import 'package:lms_chatbot/core/models/knowledge_chunks.dart';
import 'package:lms_chatbot/core/services/authservice.dart';
import 'package:lms_chatbot/core/services/constants/ApiConfigs.dart';
import 'package:lms_chatbot/core/services/pdf_processing.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final TextEditingController messageController = TextEditingController();

  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthService>();
  final _dialogService = locator<DialogService>();
  GenerativeModel? flashModel;
  GenerativeModel? fallbackModel;
  List<KnowledgeChunk> _knowledgeCache = [];
  String uploadStatus = "";
  double uploadProgress = 0;
  bool _isUploading = false;
  bool get isUploading => _isUploading;
  bool _uploadComplete = false;
  bool get uploadComplete => _uploadComplete;
  String _uploadCompleteMessage = "";
  String get uploadCompleteMessage => _uploadCompleteMessage;

  // USER DATA
  String role = "";
  String name = "User";
  bool isAiTyping = false;

  // Sidebar state
  bool _showSidebar = false;
  bool get showSidebar => _showSidebar;

  List<Map<String, dynamic>> messages = [
    {'text': 'Hello! Which topic should we learn today?', 'isUser': false},
  ];

  Color get primaryColor {
    if (role.isEmpty) return Colors.grey;
    return role == "teacher" ? Colors.blue : Colors.pink;
  }

  Color get backgroundColor {
    if (role.isEmpty) return Colors.grey.shade50;
    return role == "teacher" ? Colors.blue.shade50 : Colors.pink.shade50;
  }

  Color get drawerColor {
    if (role.isEmpty) return Colors.grey.shade200;
    return role == "teacher" ? Colors.blue.shade100 : Colors.pink.shade100;
  }

  Future<void> init() async {
    setBusy(true);

    try {
      flashModel = GenerativeModel(
        model: 'models/gemini-3.5-flash',
        apiKey: ApiConfigs.API_KEY,
      );

      fallbackModel = GenerativeModel(
        model: 'models/gemini-2.5-flash',
        apiKey: ApiConfigs.API_KEY,
      );

      await loadKnowledgeBase();

      final userData = await _authService.getUserData();
      if (userData != null) {
        role = userData['role'] ?? 'student';
        name = userData['name'] ?? 'User';
      }
    } catch (e) {
      debugPrint("Error during init: $e");
    }

    setBusy(false);
    notifyListeners();
  }

  Future<void> loadKnowledgeBase() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('knowledge_chunks')
        .orderBy('uploadedAt', descending: true)
        .limit(1)
        .get();

    _knowledgeCache = snapshot.docs.map((doc) {
      return KnowledgeChunk(
        content: '',
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

  Future<void> processPdfForKnowledgeBase() async {
    if (_isUploading) {
      await _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Upload In Progress',
        description:
            'Please wait for the current file upload to finish before uploading another file.',
      );
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      _isUploading = true;
      notifyListeners();

      int successCount = 0;
      final errors = <String>[];

      for (int i = 0; i < result.files.length; i++) {
        final pickedFile = result.files[i];

        uploadStatus =
            "Uploading ${pickedFile.name}\n(${i + 1}/${result.files.length})";
        uploadProgress = (i + 1) / result.files.length;
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 50));

        final path = pickedFile.path;
        if (path == null) {
          errors.add('"${pickedFile.name}": file not found on device.');
          continue;
        }

        final sizeCheck = validatePdfSize(path, pickedFile.name);
        if (!sizeCheck.isValid) {
          errors.add(sizeCheck.error!);
          continue;
        }

        try {
          uploadStatus = "Reading ${pickedFile.name}...";
          uploadProgress = 0;
          notifyListeners();

          int chunkCount = 0;
          bool hasContent = false;

          await processPdfPages(
            filePath: path,
            onChunk: (chunk) async {
              hasContent = true;
              chunkCount++;
              uploadStatus =
                  "Uploading ${pickedFile.name}\nChunk $chunkCount";
              notifyListeners();

              await _saveSingleChunk(
                fileName: pickedFile.name,
                chunk: chunk,
                chunkIndex: chunkCount - 1,
              );
            },
          );

          await Future.delayed(const Duration(milliseconds: 100));

          if (!hasContent) {
            errors.add('"${pickedFile.name}": no text content found.');
            continue;
          }

          successCount++;
        } catch (e) {
          debugPrint("Failed to process ${pickedFile.name}: $e");
          errors.add('"${pickedFile.name}": ${e.toString()}');
        }

        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (successCount > 0) {
        _uploadCompleteMessage =
            '$successCount PDF(s) uploaded successfully';
        _uploadComplete = true;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        _uploadComplete = false;
        _uploadCompleteMessage = "";
      }

      if (errors.isNotEmpty) {
        await _dialogService.showCustomDialog(
          variant: DialogType.infoAlert,
          title: 'Upload Errors',
          description: errors.join('\n'),
        );
      }
    } catch (e) {
      await _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Error',
        description: e.toString(),
      );
    } finally {
      uploadStatus = "";
      uploadProgress = 0;
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSingleChunk({
    required String fileName,
    required String chunk,
    required int chunkIndex,
  }) async {
    final firestore = FirebaseFirestore.instance;
    const maxRetries = 3;

    final docRef = firestore.collection('knowledge_chunks').doc();

    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        await docRef.set({
          'fileName': fileName,
          'chunkIndex': chunkIndex,
          'content': chunk,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
        return;
      } catch (e) {
        debugPrint("Chunk upload attempt ${retry + 1} failed: $e");
        if (retry == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (retry + 1)));
      }
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

    if (queryWords.isEmpty) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('knowledge_chunks')
        .limit(20)
        .get();

    final scoredChunks = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final content = (doc['content'] as String).toLowerCase();
      int score = 0;

      for (final word in queryWords) {
        if (content.contains(word)) {
          score++;
        }
      }

      if (score > 0) {
        scoredChunks.add({
          'score': score,
          'content': doc['content'],
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

      if (flashModel == null || fallbackModel == null) {
        messages.add({
          'text': 'AI models are not initialized. Please restart the app.',
          'isUser': false,
        });
        notifyListeners();
        return;
      }

      GenerateContentResponse response;

      try {
        response = await flashModel!.generateContent([Content.text(prompt)]);
      } catch (apiError) {
        final errorMessage = apiError.toString();
        final is503 = errorMessage.contains('503') ||
            errorMessage.toLowerCase().contains('unavailable');

        if (is503) {
          await Future.delayed(const Duration(seconds: 2));

          response =
              await fallbackModel!.generateContent([Content.text(prompt)]);
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
