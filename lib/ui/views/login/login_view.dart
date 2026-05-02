import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'login_viewmodel.dart';

class LoginView extends StackedView<LoginViewModel> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Login to LMS Chatbot',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Email Input
              _buildTextInput(
                label: 'Email',
                hint: 'enter your email',
                icon: Icons.email,
                controller: viewModel.emailController,
              ),

              const SizedBox(height: 20),

              // Password Input
              _buildTextInput(
                label: 'Password',
                hint: 'enter your password',
                icon: Icons.lock,
                isPassword: true,
                controller: viewModel.passwordController,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: viewModel.loginPressed,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                child: const Text('Login'),
              ),

              GestureDetector(
                  onTap: () {
                    viewModel.goToRegister();
                  },
                  child: const Padding(
                    padding: const EdgeInsetsGeometry.only(top: 20),
                    child: Text("Register here"),
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  LoginViewModel viewModelBuilder(BuildContext context) => LoginViewModel();
}
