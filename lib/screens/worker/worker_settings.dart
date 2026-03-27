import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/worker_service.dart';
import '../auth/login_screen.dart';

class WorkerSettingsScreen extends StatefulWidget {
  const WorkerSettingsScreen({super.key});

  @override
  State<WorkerSettingsScreen> createState() => _WorkerSettingsScreenState();
}

class _WorkerSettingsScreenState extends State<WorkerSettingsScreen> {
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String _phone = '';
  double _rating = 0.0;
  int _reviews = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await WorkerService.fetchSettings();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _fullName = data['profile']['full_name'] ?? '';
          _email = data['profile']['email'] ?? '';
          _phone = data['profile']['phone'] ?? '';
          _rating = double.tryParse(data['profile']['average_rating'].toString()) ?? 0.0;
          _reviews = int.tryParse(data['profile']['total_reviews'].toString()) ?? 0;
          _status = data['profile']['availability_status'] ?? 'offline';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.transparent),
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
                          child: Text(_fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'W', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ),
                        const SizedBox(height: 16),
                        Text(_fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                            const SizedBox(width: 4),
                            Text('${_rating.toStringAsFixed(1)} ($_reviews Reviews)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: _status == 'available' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(_status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _status == 'available' ? Colors.green : Colors.orange)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildMenuItem(Icons.person_outline_rounded, 'Edit Profile Info', () {}),
                  _buildMenuItem(Icons.handyman_rounded, 'Manage Services & Portfolio', () {}),
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
