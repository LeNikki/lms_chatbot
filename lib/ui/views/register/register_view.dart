import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'register_viewmodel.dart';

class RegisterView extends StackedView<RegisterViewModel> {
  const RegisterView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    RegisterViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 30),

              _buildTextInput(
                  label: 'Full Name',
                  icon: Icons.person,
                  controller: viewModel.nameController),
              const SizedBox(height: 15),

              _buildTextInput(
                  label: 'Email',
                  icon: Icons.email,
                  controller: viewModel.emailController),
              const SizedBox(height: 15),

              _buildTextInput(
                  label: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                  controller: viewModel.passwordController),
              const SizedBox(height: 15),

              _buildTextInput(
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: viewModel.confirmPasswordController),

              const SizedBox(height: 20),

              // Role Selection Checkboxes
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title:
                          const Text("Student", style: TextStyle(fontSize: 14)),
                      value: viewModel.isStudent,
                      onChanged: (val) => viewModel.setRole(isStudent: true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title:
                          const Text("Teacher", style: TextStyle(fontSize: 14)),
                      value: viewModel.isTeacher,
                      onChanged: (val) => viewModel.setRole(isStudent: false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: viewModel.register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Register', style: TextStyle(fontSize: 18)),
              ),

              GestureDetector(
                onTap: () {
                  viewModel.goToLoginPage();
                },
                child: const Padding(
                  padding: const EdgeInsetsGeometry.only(top: 20),
                  child: Text("Already have an account"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
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
  RegisterViewModel viewModelBuilder(BuildContext context) =>
      RegisterViewModel();
}
