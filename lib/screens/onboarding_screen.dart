import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Find Trusted Professionals',
      'description': 'Browse and book verified artisans, handymen, and experts for your everyday needs instantly.',
      'icon': Icons.search_rounded,
    },
    {
      'title': 'Secure & Transparent',
      'description': 'Enjoy peace of mind with our secure escrow payment system and dedicated support team.',
      'icon': Icons.security_rounded,
    },
    {
      'title': 'Earn Kaida Points',
      'description': 'Get rewarded for every job completed or booked. Grow and earn with the Kaida Works community.',
      'icon': Icons.stars_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Text('Skip', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView( // FIXED: Allows scrolling on small screens
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.05),
                        Container(
                          height: size.height * 0.3, // Proportional height
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
                          ),
                          child: Icon(_pages[index]['icon'], size: size.height * 0.12, color: theme.colorScheme.primary),
                        ),
                        SizedBox(height: size.height * 0.05),
                        Text(
                          _pages[index]['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, height: 1.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[index]['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280), height: 1.5),
                        ),
                        const SizedBox(height: 20), // Bottom buffer
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? theme.colorScheme.primary : (isDark ? Colors.grey[800] : Colors.grey[300]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      style: OutlinedButton.styleFrom(foregroundColor: isDark ? Colors.white : theme.colorScheme.primary, side: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
