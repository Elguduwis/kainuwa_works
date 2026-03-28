import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/worker_service.dart';
import '../../utils/theme_provider.dart';
import '../auth/login_screen.dart';
import 'worker_edit_profile.dart';
import 'worker_kyc_screen.dart';
import 'worker_payout_methods_screen.dart'; // NEW

class WorkerSettingsScreen extends StatefulWidget {
  const WorkerSettingsScreen({super.key});

  @override
  State<WorkerSettingsScreen> createState() => _WorkerSettingsScreenState();
}

class _WorkerSettingsScreenState extends State<WorkerSettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  double _points = 0.0;

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
          _profileData = data['profile'];
          _points = double.tryParse(data['profile']['kaida_points']?.toString() ?? '0') ?? 0.0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final String fullName = _profileData['full_name'] ?? 'Provider';
    final String email = _profileData['email'] ?? '';
    final String profilePicture = _profileData['profile_picture'] ?? '';
    final double rating = double.tryParse(_profileData['average_rating']?.toString() ?? '0') ?? 0.0;
    final int reviews = int.tryParse(_profileData['total_reviews']?.toString() ?? '0') ?? 0;
    final String verificationStatus = _profileData['verification_status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.transparent),
      body: RefreshIndicator(
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
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(color: isDark ? Colors.white24 : theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                      clipBehavior: Clip.hardEdge,
                      child: profilePicture.isNotEmpty 
                          ? Image.network('https://works.kainuwa.africa/uploads/avatars/$profilePicture', fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.person, color: isDark ? Colors.white : theme.colorScheme.primary, size: 40))
                          : Center(child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'W', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isDark ? Colors.white : theme.colorScheme.primary))),
                    ),
                    const SizedBox(height: 16),
                    Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text('${rating.toStringAsFixed(1)} ($reviews Reviews)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: verificationStatus == 'approved' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(verificationStatus == 'approved' ? 'VERIFIED' : 'KYC PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: verificationStatus == 'approved' ? Colors.green : Colors.orange)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), border: Border.all(color: Colors.orange.withOpacity(0.3)), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.stars_rounded, color: Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_points.toStringAsFixed(0)} Kaida Points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)), const Text('Earn points by completing jobs!', style: TextStyle(fontSize: 12, color: Colors.orange))])),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildMenuItem(Icons.edit_rounded, 'Edit Profile Details', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerEditProfileScreen(profileData: _profileData))).then((_) => _loadData());
              }, isDark, theme),
              _buildMenuItem(Icons.verified_user_rounded, 'Upload KYC Documents', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerKycScreen())).then((_) => _loadData());
              }, isDark, theme),
              _buildMenuItem(Icons.account_balance_rounded, 'Payout Methods', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerPayoutMethodsScreen()));
              }, isDark, theme),
              const SizedBox(height: 24),
              
              SwitchListTile(
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: isDark ? Colors.white : theme.colorScheme.primary),
                value: isDark,
                activeColor: isDark ? Colors.white : theme.colorScheme.primary,
                onChanged: (val) => themeProvider.toggleTheme(val),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              const SizedBox(height: 16),
              
              ListTile(
                onTap: () async {
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20)),
                title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: isDark ? Colors.white : theme.colorScheme.primary, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
