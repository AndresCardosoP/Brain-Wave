import 'package:flutter/material.dart';

// A custom TextFormField widget that can be reused across the app
class MyTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final Widget label;
  final bool obscureText;

  // Constructor for initializing the custom text field
  const MyTextFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    double textSize = 30;

    // Apply scaling for screens under 600 logical pixels
    if (screenHeight < 650) {
      textSize = 15;
    }
    if (screenHeight > 750) {
      textSize = 400;
    }
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
    } else {
      if (screenHeight > 750) {
        textSize = 150;
      }
    }

    return Padding(
      // Padding around the text field
      padding: EdgeInsets.only(
        top: 25,
        bottom: 5,
        left: textSize,
        right: textSize,
      ),
      child: TextFormField(
        // Assigning the controller to the text field
        controller: controller,
        // Setting the decoration of the text field
        decoration: InputDecoration(
          // Label for the text field
          label: label,
          // Border style for the text field
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // Whether to obscure the text
        obscureText: obscureText,
      ),
    );
  }
}
