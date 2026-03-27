import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../client/client_home.dart';
import '../worker/worker_home.dart';
import 'register_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleLogin() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both email/phone and password')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.login(identifier, password);
    setState(() => _isLoading = false);
    
    if (!mounted) return;

    if (result['status'] == 'success') {
      if (result['requires_otp'] == true) {
        // Automatically request a fresh OTP and navigate to OTP screen
        await AuthService.resendOtp(result['email']);
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: result['email'], role: 'client'))); // Role doesn't matter much on login flow
        return;
      }

      final role = result['user']['role'];
      if (role == 'worker') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WorkerHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClientHomeScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Login failed'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.handyman_rounded, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text('Welcome back', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Enter your details to access your account.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280))),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.grey[800]! : Colors.transparent),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Email or Phone Number', theme),
                      _buildTextField(controller: _emailController, hint: 'name@example.com', icon: Icons.person_outline, theme: theme),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel('Password', theme),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: Text('Forgot?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _passwordController, hint: '••••••••', icon: Icons.lock_outline, isPassword: true, theme: theme),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6B7280))),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text('Create one now', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)));
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF), size: 22),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF), size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
            : null,
        filled: true,
        fillColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
