import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../auth/login_screen.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String _phone = '';
  double _points = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ClientService.fetchProfile();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _fullName = data['profile']['full_name'];
          _email = data['profile']['email'];
          _phone = data['profile']['phone'];
          _points = (data['profile']['kaida_points'] as num).toDouble();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            color: theme.colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'C',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(_fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        Text(_phone, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                        Text(_email, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_points.toStringAsFixed(0)} Kaida Points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF92400E))),
                              const Text('Earn points by booking and reviewing!', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildMenuItem(Icons.person_outline_rounded, 'Edit Profile', () {}),
                  _buildMenuItem(Icons.shield_outlined, 'Security & Password', () {}),
                  _buildMenuItem(Icons.help_outline_rounded, 'Help & Support', () {}),
                  const SizedBox(height: 24),
                  
                  ListTile(
                    onTap: () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                    ),
                    title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF4B5563), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
