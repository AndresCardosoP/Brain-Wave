import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final Widget child;

  const MyButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(
        top: 25,
        left: 25,
        right: 25,
      ),
      child: GestureDetector(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            width: size.width,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: child,
          )),
    );
  }
}

class SignUpButton extends StatelessWidget {
  final Function()? onTap;
  const SignUpButton({
      super.key,
      required this.onTap,
    });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 20,
      ),
      child: SizedBox(
          child: Column(
        children: [
          const Text("Don't have an account?"),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'Sign up >>',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      )),
    );
  }
}

class spacerWithLine extends StatelessWidget {
  const spacerWithLine({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(
        top: 75,
        bottom: 20,
      ),
      child: Container(
        width: size.width,
        height: 2,
        decoration: const BoxDecoration(
          color: Colors.blue,
        ),
      ),
    );
  }
}

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