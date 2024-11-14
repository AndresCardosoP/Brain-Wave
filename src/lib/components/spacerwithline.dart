import 'package:flutter/material.dart';

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