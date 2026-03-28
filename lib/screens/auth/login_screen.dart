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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your credentials')));
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.login(identifier, password);
    setState(() => _isLoading = false);
    
    if (!mounted) return;

    if (result['status'] == 'success') {
      if (result['requires_otp'] == true) {
        await AuthService.resendOtp(result['email']);
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: result['email'], role: 'client')));
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
    final textColor = theme.textTheme.bodyLarge?.color;
    final borderColor = isDark ? Colors.grey[700]! : const Color(0xFFD1D5DB);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 28),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stylized Hero Illustration Placeholder
              Center(
                child: SizedBox(
                  height: 160,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 20, top: 20,
                        child: CircleAvatar(radius: 60, backgroundColor: theme.colorScheme.primary.withOpacity(0.15)),
                      ),
                      Positioned(
                        right: 10, bottom: 20,
                        child: CircleAvatar(radius: 40, backgroundColor: theme.colorScheme.secondary.withOpacity(0.2)),
                      ),
                      Container(
                        width: 100, height: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 32),
                            const SizedBox(height: 8),
                            Container(width: 50, height: 4, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                            const SizedBox(height: 4),
                            Container(width: 30, height: 4, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text('Log In', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1.0)),
              const SizedBox(height: 4),
              Text('To access Kaida Works', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),

              _buildLabel('Email or Phone', textColor),
              _buildTextField(controller: _emailController, hint: 'Enter Email Address or Phone', borderColor: borderColor, theme: theme),
              const SizedBox(height: 20),
              
              _buildLabel('Password', textColor),
              _buildTextField(controller: _passwordController, hint: 'Enter Password', isPassword: true, borderColor: borderColor, theme: theme),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Forgot Password?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary.withOpacity(0.9), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Simulated Google G Icon
                      Text('G', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
                      const SizedBox(width: 12),
                      const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6B7280))),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('Sign Up', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[600], borderRadius: BorderRadius.circular(30)),
                  child: const Text("Using default location: Gombi, Adamawa", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color? textColor) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)));
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isPassword = false, required Color borderColor, required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF), fontWeight: FontWeight.w400, fontSize: 14),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF), size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
            : null,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
      ),
    );
  }
}
