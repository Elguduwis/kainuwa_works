import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

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
        fontFamily: 'Inter', // Assuming standard modern sans-serif
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7351FF),
          primary: const Color(0xFF7351FF),
          secondary: const Color(0xFFF6C101), // Brand Accent
          background: const Color(0xFFF9FAFB), // Gray 50
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
    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 2500), () {});
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman_rounded, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Kainuwa Works',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
