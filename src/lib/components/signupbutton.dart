import 'package:flutter/material.dart';

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