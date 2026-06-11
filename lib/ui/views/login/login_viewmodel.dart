import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:lms_chatbot/app/app.locator.dart';
import 'package:lms_chatbot/app/app.router.dart';
import 'package:lms_chatbot/core/services/authservice.dart';
import 'package:lms_chatbot/ui/views/home/home_view.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class LoginViewModel extends BaseViewModel {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  AuthService get _authService => locator<AuthService>();

  Future<void> loginPressed() async {
    setBusy(true);

    try {
      await _authService.loginUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ✅ SUCCESS → go to home
      _navigationService.clearStackAndShowView(const HomeView());
    } on FirebaseAuthException catch (e) {
      // ❌ Firebase errors
      if (e.code == 'user-not-found') {
        _dialogService.showDialog(
          title: "Login Failed",
          description: "No user found with this email.",
        );
      } else if (e.code == 'wrong-password') {
        _dialogService.showDialog(
          title: "Login Failed",
          description: "Incorrect password.",
        );
      } else if (e.code == 'invalid-email') {
        _dialogService.showDialog(
          title: "Login Failed",
          description: "Invalid email format.",
        );
      } else {
        _dialogService.showDialog(
          title: "Login Failed",
          description: e.message ?? "Something went wrong.",
        );
      }
    } catch (e) {
      // ❌ Generic error
      _dialogService.showDialog(
        title: "Error",
        description: e.toString(),
      );
    } finally {
      setBusy(false);
    }
  }

  void goToRegister() {
    _navigationService.navigateToRegisterView();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
