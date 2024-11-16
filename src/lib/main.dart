import 'package:flutter/material.dart';
import 'utils/constant.dart' as utils;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:src/screens/login_page.dart';
import 'package:src/screens/home_screen.dart';
import 'package:src/screens/signup_page.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://rphcagdsmtmhjyrqfzmi.supabase.co/',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwaGNhZ2RzbXRtaGp5cnFmem1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE1MzY4NzIsImV4cCI6MjA0NzExMjg3Mn0.eeVx9hQOsbebMwMjrI5hjmjK3D6GcKZRsUjGnEcHilI',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Supabase Flutter',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: utils.client.auth.currentSession != null ? '/home' : '/',
        routes: {
          '/': (content) => const LoginPage(),
          '/signup': (content) => const SignUpPage(),
          '/login': (content) => const LoginPage(),
          '/home': (content) => const HomeScreen(),
        });
  }
}
