import 'package:flutter/material.dart';
import 'package:src/utils/constant.dart' as utils;
import 'package:src/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:src/screens/login_page.dart';
import 'package:src/screens/home_screen.dart';
import 'package:src/screens/signup_page.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Notification Service
  await NotificationService().init();
  tz.initializeTimeZones();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR-URL-HERE',
    anonKey:
      'YOUR-KEY-HERE',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client; // Supabase client instance

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
        initialRoute: // Check if the user is authenticated
            utils.client.auth.currentSession != null ? '/home' : '/',
        routes: { // Define the routes
          '/': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomeScreen(),
        });
  }
}