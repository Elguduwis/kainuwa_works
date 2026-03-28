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

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    
    // Combine names for backend compatibility
    final fullName = '$firstName $lastName';

    final result = await AuthService.register({
      'full_name': fullName,
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
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 28),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              if (Navigator.canPop(context)) Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _currentStep == 0 
            ? _buildRoleSelection(theme, textColor) 
            : _buildRegistrationForm(theme, textColor, isDark),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(ThemeData theme, Color? textColor) {
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Join Kaida Works', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1.0)),
          const SizedBox(height: 4),
          Text('Select your account type', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          _buildRoleCard('Hire Professionals', 'I need to find and book experts.', Icons.search_rounded, 'client', theme, textColor, isDark),
          const SizedBox(height: 16),
          _buildRoleCard('Work as a Provider', 'I want to offer my services and earn.', Icons.work_outline_rounded, 'worker', theme, textColor, isDark),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String title, String description, IconData icon, String role, ThemeData theme, Color? textColor, bool isDark) {
    final isSelected = _selectedRole == role;
    final borderColor = isDark ? Colors.grey[700]! : const Color(0xFFD1D5DB);
    
    return GestureDetector(
      onTap: () => setState(() { _selectedRole = role; _currentStep = 1; }),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.grey[800] : const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]), size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)), const SizedBox(height: 4), Text(description, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.4))])),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(ThemeData theme, Color? textColor, bool isDark) {
    final borderColor = isDark ? Colors.grey[700]! : const Color(0xFFD1D5DB);

    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              height: 120,
              width: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: 20, top: 10,
                    child: CircleAvatar(radius: 40, backgroundColor: theme.colorScheme.secondary.withOpacity(0.2)),
                  ),
                  Container(
                    width: 80, height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded, color: theme.colorScheme.primary, size: 32),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Sign Up', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1.0)),
          const SizedBox(height: 4),
          Text(_selectedRole == 'client' ? 'To find a service' : 'To offer your services', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),

          _buildLabel('First name', textColor),
          _buildTextField(controller: _firstNameController, hint: 'Enter First name', borderColor: borderColor, theme: theme),
          const SizedBox(height: 16),

          _buildLabel('Last name', textColor),
          _buildTextField(controller: _lastNameController, hint: 'Enter Last name', borderColor: borderColor, theme: theme),
          const SizedBox(height: 16),

          _buildLabel('Email', textColor),
          _buildTextField(controller: _emailController, hint: 'Enter Email Address', keyboardType: TextInputType.emailAddress, borderColor: borderColor, theme: theme),
          const SizedBox(height: 16),
          
          _buildLabel('Phone Number', textColor),
          _buildTextField(controller: _phoneController, hint: 'Enter Phone Number', keyboardType: TextInputType.phone, borderColor: borderColor, theme: theme),
          const SizedBox(height: 16),

          _buildLabel('Password', textColor),
          _buildTextField(controller: _passwordController, hint: 'Create Password', isPassword: true, borderColor: borderColor, theme: theme),
          const SizedBox(height: 24),

          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]),
              children: [
                const TextSpan(text: "By clicking 'Create account', you are agreeing to our "),
                TextSpan(text: "Terms & Conditions", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                const TextSpan(text: " and "),
                TextSpan(text: "Privacy Policy", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary.withOpacity(0.9), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  Text('G', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(width: 12),
                  const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color? textColor) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)));

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isPassword = false, TextInputType? keyboardType, required Color borderColor, required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF), fontWeight: FontWeight.w400, fontSize: 14),
        suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF), size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
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
