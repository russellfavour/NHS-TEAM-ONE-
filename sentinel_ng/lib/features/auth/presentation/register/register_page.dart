import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../bloc/auth_bloc.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  /// Registration succeeded but requires email verification before a token is
  /// issued. Show a success dialog, then send the user to login.
  void _showRegistrationSuccess(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.primaryGreen),
        title: const Text('Check your email'),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(AppRoutes.login);
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(Icons.person_add_outlined, size: 64, color: AppColors.primaryGreen),
                const SizedBox(height: 16),
                Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Join your community safety network', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 32),

                TextFormField(controller: nameController, decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryGreen), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v == null || v.isEmpty ? 'Enter your full name' : null),
                const SizedBox(height: 16),

                TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryGreen), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null),
                const SizedBox(height: 16),

                TextFormField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryGreen), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
                const SizedBox(height: 16),

                TextFormField(controller: confirmPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryGreen), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v != passwordController.text ? 'Passwords do not match' : null),
                const SizedBox(height: 32),

                BlocConsumer<AuthBloc, AuthState>(listener: (context, state) {
                  if (state is AuthAuthenticated) context.go(AppRoutes.home);
                  else if (state is AuthRegistered) _showRegistrationSuccess(context, state.message ?? 'Registration successful. Please check your email to verify your account.');
                  else if (state is AuthError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure.message)));
                }, builder: (context, state) {
                  if (state is AuthLoading) return const Center(child: CircularProgressIndicator());
                  return ElevatedButton(onPressed: () {
                    if (formKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(RegisterEvent(name: nameController.text, email: emailController.text, password: passwordController.text));
                    }
                  }, child: const Text('Create Account'));
                }),
                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account? ', style: TextStyle(color: Colors.grey[600])),
                  GestureDetector(onTap: () => context.go(AppRoutes.login), child: const Text('Sign In', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
