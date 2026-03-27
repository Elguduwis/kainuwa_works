import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0; 
  String? _selectedRole; 

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await AuthService.register({
      'full_name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': _selectedRole ?? 'client',
    });

    setState(() => _isLoading = false);
    
    if (!mounted) return;

    if (result['status'] == 'success' && result['requires_otp'] == true) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: email, role: _selectedRole ?? 'client')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Registration failed'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final subTextColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final cardColor = isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _currentStep == 0 
            ? _buildRoleSelection(theme, textColor, subTextColor, cardColor) 
            : _buildRegistrationForm(theme, textColor, subTextColor, cardColor),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(ThemeData theme, Color textColor, Color subTextColor, Color cardColor) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How do you want to use Kaida Works?', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textColor, height: 1.2, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Select your account type to continue', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: subTextColor)),
          const SizedBox(height: 40),
          _buildRoleCard('Hire Providers', 'I need to find and book professionals for a job.', Icons.search_rounded, 'client', theme, textColor, subTextColor, cardColor),
          const SizedBox(height: 16),
          _buildRoleCard('Work as Provider', 'I want to offer my services, get booked, and earn money.', Icons.work_outline_rounded, 'worker', theme, textColor, subTextColor, cardColor),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String title, String description, IconData icon, String role, ThemeData theme, Color textColor, Color subTextColor, Color cardColor) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() { _selectedRole = role; _currentStep = 1; }),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : (cardColor == Colors.white ? const Color(0xFFE5E7EB) : const Color(0xFF374151)), width: 2),
        ),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : (cardColor == Colors.white ? const Color(0xFFF3F4F6) : const Color(0xFF374151)), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: isSelected ? Colors.white : subTextColor, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)), const SizedBox(height: 4), Text(description, style: TextStyle(fontSize: 13, color: subTextColor, height: 1.4))])),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(ThemeData theme, Color textColor, Color subTextColor, Color cardColor) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_selectedRole == 'client' ? 'Sign up as Client' : 'Sign up as Provider', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Complete your profile details below.', style: TextStyle(fontSize: 15, color: subTextColor)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Full Name', textColor),
                _buildTextField(controller: _nameController, hint: 'John Doe', icon: Icons.person_outline, cardColor: cardColor, textColor: textColor),
                const SizedBox(height: 16),
                _buildLabel('Email Address', textColor),
                _buildTextField(controller: _emailController, hint: 'name@example.com', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress, cardColor: cardColor, textColor: textColor),
                const SizedBox(height: 16),
                _buildLabel('Phone Number', textColor),
                _buildTextField(controller: _phoneController, hint: '08012345678', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, cardColor: cardColor, textColor: textColor),
                const SizedBox(height: 16),
                _buildLabel('Password', textColor),
                _buildTextField(controller: _passwordController, hint: '••••••••', icon: Icons.lock_outline, isPassword: true, cardColor: cardColor, textColor: textColor),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isLoading ? null : _handleRegister, style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)));

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, TextInputType? keyboardType, required Color cardColor, required Color textColor}) {
    final fillColor = cardColor == Colors.white ? const Color(0xFFF3F4F6) : const Color(0xFF374151);
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
        suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9CA3AF), size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
