import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/client_home.dart';
import 'screens/worker/worker_home.dart';

void main() {
  runApp(const KainuwaWorksApp());
}

class KainuwaWorksApp extends StatelessWidget {
  const KainuwaWorksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kainuwa Works',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7351FF),
          primary: const Color(0xFF7351FF),
          secondary: const Color(0xFFF6C101),
          background: const Color(0xFFF9FAFB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  // Auto-Login Logic Engine
  _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 2500)); // Show splash screen briefly
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final role = prefs.getString('role');
    
    if (!mounted) return;

    if (userId != null && role != null) {
      if (role == 'worker') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WorkerHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClientHomeScreen()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Look! We are using your actual downloaded logo here!
            Image.asset('assets/img/logo.png', width: 120, height: 120, errorBuilder: (context, error, stackTrace) => const Icon(Icons.handyman_rounded, size: 80, color: Colors.white)),
            const SizedBox(height: 20),
            const Text(
              'Kainuwa Works',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),
            const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}
