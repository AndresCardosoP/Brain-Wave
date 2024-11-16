import 'package:flutter/material.dart';
import 'package:src/components/textbox.dart';
import 'package:src/components/button.dart';
import 'package:src/utils/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ///initialize controller for email and password

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
          SizedBox(height: 50),
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
          MyButton(
            onTap: () async {
              try {
                await client.auth.signInWithPassword(
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
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text('Unexpected error')),
                // );
                // if (!context.mounted) return;
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text('Unexpected error')),
                // );
              }
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
            },
            child: const Text("Don't have an account? Sign Up"),
          ),
        ],
      ),
    );
  }
}