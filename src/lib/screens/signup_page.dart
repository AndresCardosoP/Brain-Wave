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
  bool isLoading = false;

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
              if (_passwordController.text != _confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              try {
                await client.auth.signUp(
                  email: _emailController.text,
                  password: _passwordController.text,
                );
                if (mounted) {
                  Navigator.pushNamed(context, '/home');
                }
              } on AuthException catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unexpected error')),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unexpected error')),
                );
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
