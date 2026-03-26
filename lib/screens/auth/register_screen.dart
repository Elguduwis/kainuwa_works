import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0; // 0 for Role Selection, 1 for Form
  String? _selectedRole; // 'client' or 'worker'

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleRegister() async {
    setState(() => _isLoading = true);
    // TODO: Connect to backend API
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration Pending for $_selectedRole...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
            );
          },
          child: _currentStep == 0 ? _buildRoleSelection(theme) : _buildRegistrationForm(theme),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'How do you want to use Kainuwa?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), height: 1.2, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your account type to continue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 40),
          _buildRoleCard(
            title: 'Hire Providers',
            description: 'I need to find and book professionals for a job.',
            icon: Icons.search_rounded,
            role: 'client',
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            title: 'Work as Provider',
            description: 'I want to offer my services, get booked, and earn money.',
            icon: Icons.work_outline_rounded,
            role: 'worker',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({required String title, required String description, required IconData icon, required String role, required ThemeData theme}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _currentStep = 1; // Auto-advance
        });
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : const Color(0xFFE5E7EB), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF6B7280), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _selectedRole == 'client' ? 'Sign up as Client' : 'Sign up as Provider',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your profile details below.',
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Full Name'),
                _buildTextField(controller: _nameController, hint: 'John Doe', icon: Icons.person_outline),
                const SizedBox(height: 16),
                
                _buildLabel('Email Address'),
                _buildTextField(controller: _emailController, hint: 'name@example.com', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                
                _buildLabel('Phone Number'),
                _buildTextField(controller: _phoneController, hint: '08012345678', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                
                _buildLabel('Password'),
                _buildTextField(controller: _passwordController, hint: '••••••••', icon: Icons.lock_outline, isPassword: true),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'By registering, you agree to our Terms of Service.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9CA3AF), size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
