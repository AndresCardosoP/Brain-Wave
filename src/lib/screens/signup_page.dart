// Import necessary Flutter packages and custom components
import 'package:flutter/material.dart';
import 'package:src/components/textbox.dart';
import 'package:src/components/button.dart';
import 'package:src/utils/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define a StatefulWidget for the Sign-Up Page
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

// State class for managing the SignUpPage's state
class _SignUpPageState extends State<SignUpPage> {
  // Controllers for managing text input in form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Supabase client instance for database and authentication operations
  final SupabaseClient client = Supabase.instance.client;

  // Boolean to track loading state for UI updates
  bool isLoading = false;

  // Function to create a new user with the provided details
  Future<bool> createUser({
    required final String email,
    required final String password,
    required final String ConfirmPassword,
    required final String firstName,
    required final String lastName,
  }) async {
    // Check if password and confirmation password match
    if (password != ConfirmPassword) {
      context.showErrorMessage("Passwords do not match");
      return false;
    }

    try {
      // Sign up the user using Supabase authentication
      final response =
          await client.auth.signUp(email: email, password: password);

      // Retrieve the user's ID after successful sign-up
      final userId = response.user!.id;

      // Insert additional user details into the 'users' table
      await client.from('users').insert({
        'auth_id': userId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
      });

      return true; // Return true if sign-up is successful
    } catch (e) {
      // Display an error message if sign-up fails
      context.showErrorMessage('Sign up failed: $e');
      return false; // Return false on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    double scaleFactor = 1.0;
    double logosize = 150.0;

    // Apply scaling for screens under 600 logical pixels
    if (screenHeight < 650) {
      scaleFactor = 0.98;
      logosize = 120.0;
    }

    // Your existing content widget
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Display an icon at the top
        Icon(
          Icons.waves_sharp,
          size: logosize,
          color: Colors.blue,
        ),
        // Display the app's name with styling
        const Text('BrainWave',
            style: TextStyle(
                fontSize: 50, fontWeight: FontWeight.bold, color: Colors.blue)),
        // Text fields for user input (First Name, Last Name, Email, Password)
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
        // Button to trigger user sign-up
        MyButton(
          onTap: () async {
            // Attempt to create a user account with provided input
            bool success = await createUser(
              email: _emailController.text,
              password: _passwordController.text,
              ConfirmPassword: _confirmPasswordController.text,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
            );
            // Navigate to the home page on successful sign-up
            if (success) {
              Navigator.pushNamed(context, '/home');
            }
          },
          child: const Text('Sign Up'), // Button label
        ),
        // Text button to navigate to the login page
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          child: const Text('Already have an account? Log in'),
        ),
      ],
    );

    // Check if the screen is in portrait mode and screen height condition
    if (MediaQuery.of(context).orientation == Orientation.portrait &&
        screenHeight > 900) {
      // Add top padding to move content down
      content = Padding(
        padding:
            const EdgeInsets.only(top: 220.0), // Adjust the value as needed
        child: content,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Transform.scale(
            scale: scaleFactor,
            child: content,
          ),
        ),
      ),
    );
  }
}
