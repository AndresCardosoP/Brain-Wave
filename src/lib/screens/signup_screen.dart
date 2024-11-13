// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/constant.dart';
import 'login_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reTypePasswordController = TextEditingController();
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> createUser({
    required final String email,
    required final String password,
    required final String reTypePassword,
  }) async {
    if (password != reTypePassword) {
      context.showErrorMessage("Passwords do not match");
      return false;
    }

    final response = await _client.auth.signUp(email: email, password: password);
    if (response.session == null) {
      context.showErrorMessage('Sign up failed');
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              // Re-type Password Field
              TextFormField(
                controller: _reTypePasswordController,
                decoration: const InputDecoration(labelText: 'Re-type Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              // Sign Up Button
              ElevatedButton(
                onPressed: () async {
                  bool success = await createUser(
                    email: _emailController.text,
                    password: _passwordController.text,
                    reTypePassword: _reTypePasswordController.text,
                  );
                  if (success) {
                    // Navigation is handled by AuthState listener
                  }
                },
                child: const Text('Sign Up'),
              ),
              // Navigate to Login
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}