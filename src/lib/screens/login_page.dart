import 'package:flutter/material.dart';
import 'package:src/components/spacerwithline.dart';
import 'package:src/components/textformfield.dart';
import 'package:src/components/button.dart';
import 'package:src/components/signupbutton.dart';
import 'package:src/utils/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:src/services/db_helper.dart'; // Import the updated DBHelper class

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Initialize controllers for email and password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  /// Initialize the database helper
  final dbHelper = DBHelper.instance();

  /// Auto-fill credentials if stored in local database
  void _autoFillCredentials() async {
    final credentials = await dbHelper.getCredentials();
    if (credentials != null) {
      setState(() {
        _emailController.text = credentials['username'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
      });
    }
  }

  /// Save credentials to local database after successful login
  Future<void> _saveCredentials(String email, String password) async {
    await dbHelper.saveCredentials(email, password);
  }

  /// Handle user login
  Future<void> _handleLogin() async {
    setState(() {
      isLoading = true;
    });

    try {
      await client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save credentials locally
      await _saveCredentials(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Navigate to home screen
      if (mounted) {
        Navigator.pushNamed(context, '/home');
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _autoFillCredentials(); // Attempt to auto-fill credentials on load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.water,
              size: 150,
              color: Colors.blue,
            ),
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
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
            MyButton(
              onTap: isLoading ? null : _handleLogin, // Disable button while loading
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
            const spacerWithLine(),
            SignUpButton(
              onTap: () {
                Navigator.pushNamed(context, '/signup');
              },
            ),
          ],
        ),
      ),
    );
  }
}
