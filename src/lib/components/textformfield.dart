import 'package:flutter/material.dart';

class MyTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final Widget label;
  final bool obscureText;

  const MyTextFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 25,
        bottom: 25,
        right: 25,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          label: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        obscureText: obscureText, // Pass the obscureText property here
      ),
    );
  }
}