import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:lms_chatbot/app/app.locator.dart';
import 'package:lms_chatbot/app/app.router.dart';
import 'package:lms_chatbot/core/services/authservice.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class RegisterViewModel extends BaseViewModel {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  AuthService get _authService => locator<AuthService>();

  bool _isStudent = false;
  bool _isTeacher = false;

  bool get isStudent => _isStudent;
  bool get isTeacher => _isTeacher;

  void setRole({required bool isStudent}) {
    if (isStudent) {
      _isStudent = true;
      _isTeacher = false;
    } else {
      _isTeacher = true;
      _isStudent = false;
    }
    notifyListeners();
  }

  void goToLoginPage() {
    _navigationService.navigateToLoginView();
  }

  Future<void> register() async {
    setBusy(true);

    try {
      if (passwordController.text != confirmPasswordController.text) {
        _dialogService.showDialog(
          title: "Error",
          description: "Passwords do not match",
        );
        return;
      }

      await _authService.registerUser(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        role: _isStudent ? "student" : "teacher",
        classroomCode: "ABC123",
      );

      _dialogService.showDialog(
        title: "Success",
        description: "Account created successfully",
      );
    } catch (e) {
      _dialogService.showDialog(
        title: "Error",
        description: "Error creating an account, make sure to fill up all required fields",
      );
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
