// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rctmaycyppknxmotjssx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjdG1heWN5cHBrbnhtb3Rqc3N4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA5NTc1OTQsImV4cCI6MjA0NjUzMzU5NH0.DiJ-xslKre1YMEVjnIaXHdcRORo_aT6RC0kGCjtRKpQ',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainWave',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthenticationState(), // Changed from HomeScreen to AuthenticationState
    );
  }
}

class AuthenticationState extends StatefulWidget {
  const AuthenticationState({Key? key}) : super(key: key);

  @override
  _AuthenticationStateState createState() => _AuthenticationStateState();
}

class _AuthenticationStateState extends State<AuthenticationState> {
  final SupabaseClient _client = Supabase.instance.client;
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();

    // Listen to authentication state changes
    _authStream = _client.auth.onAuthStateChange;
    _authStream.listen((stateChange) {
      final event = stateChange.event;
      final session = stateChange.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (event == AuthChangeEvent.signedOut) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _client.auth.currentSession;
    if (session != null) {
      // If user is already signed in, navigate to HomeScreen
      return const HomeScreen();
    } else {
      // If not signed in, navigate to LoginScreen
      return const LoginPage();
    }
  }
}