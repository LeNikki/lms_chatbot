import 'package:flutter/material.dart';
import 'package:lms_chatbot/app/app.locator.dart';
import 'package:lms_chatbot/app/app.router.dart';
import 'package:lms_chatbot/core/services/authservice.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends BaseViewModel {
  final TextEditingController messageController = TextEditingController();

  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthService>();

  // 🔥 USER DATA
  String role = "student";
  String name = "User";

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
  return role == "teacher"
      ? Colors.blue.shade50
      : Colors.pink.shade50;
}

Color get drawerColor {
  return role == "teacher"
      ? Colors.blue.shade100
      : Colors.pink.shade100;
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

  void _mockAiResponse() async {
    await Future.delayed(const Duration(seconds: 1));

    messages.add({
      'text': 'This is a simple AI response.',
      'isUser': false,
    });

    notifyListeners();
  }

  void logout() {
    _navigationService.navigateToLoginView();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}