import 'package:flutter/material.dart';
import 'package:src/components/textbox.dart';
import 'package:src/components/button.dart';
import 'package:src/utils/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final SupabaseClient client = Supabase.instance.client;
  bool isLoading = false;

  Future<bool> createUser({
    required final String email,
    required final String password,
    required final String ConfirmPassword,
    required final String firstName,
    required final String lastName,
  }) async {
    if (password != ConfirmPassword) {
      context.showErrorMessage("Passwords do not match");
      return false;
    }

    try {
      final response =
          await client.auth.signUp(email: email, password: password);
      // Insert additional user information into public.users table
      final userId = response.user!.id;
      await client.from('users').insert({
        'auth_id': userId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
      });

      return true;
    } catch (e) {
      context.showErrorMessage('Sign up failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.waves_sharp,
            size: 150,
            color: Colors.blue,
          ),
          const Text('BrainWave',
              style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          MyTextFormField(
            controller: _firstNameController,
            label: const Text('First Name'),
            obscureText: false,
          ),
          MyTextFormField(
            controller: _lastNameController,
            label: const Text('Last Name'),
            obscureText: false,
          ),
          MyTextFormField(
            controller: _emailController,
            label: const Text('Email Address'),
            obscureText: false,
          ),
          MyTextFormField(
            controller: _passwordController,
            label: const Text('Password'),
            obscureText: true,
          ),
          MyTextFormField(
            controller: _confirmPasswordController,
            label: const Text('Confirm Password'),
            obscureText: true,
          ),
          MyButton(
            onTap: () async {
              bool success = await createUser(
                email: _emailController.text,
                password: _passwordController.text,
                ConfirmPassword: _confirmPasswordController.text,
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
              );
              if (success) {
                Navigator.pushNamed(context, '/home');
              }
            },
            child: const Text('Sign Up'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}
