import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/worker_service.dart';
import '../../utils/theme_provider.dart';
import '../auth/login_screen.dart';
import 'portfolio_manager_screen.dart';

class WorkerSettingsScreen extends StatefulWidget {
  const WorkerSettingsScreen({super.key});

  @override
  State<WorkerSettingsScreen> createState() => _WorkerSettingsScreenState();
}

class _WorkerSettingsScreenState extends State<WorkerSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _email = '';
  double _rating = 0.0;
  int _reviews = 0;
  String _status = '';
  String _profilePicture = '';
  File? _newAvatar;

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
          _nameController.text = data['profile']['full_name'] ?? '';
          _phoneController.text = data['profile']['phone'] ?? '';
          _bioController.text = data['profile']['bio'] ?? '';
          _email = data['profile']['email'] ?? '';
          _rating = double.tryParse(data['profile']['average_rating'].toString()) ?? 0.0;
          _reviews = int.tryParse(data['profile']['total_reviews'].toString()) ?? 0;
          _status = data['profile']['availability_status'] ?? 'offline';
          _profilePicture = data['profile']['profile_picture'] ?? '';
        }
      });
    }
  }

  Future<void> _pickAvatar() async {
    var photoStatus = await Permission.photos.request();
    var storageStatus = await Permission.storage.request();
    if (photoStatus.isGranted || storageStatus.isGranted) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final compressed = await FlutterImageCompress.compressAndGetFile(picked.path, '${picked.path}_avatar.jpg', quality: 50);
        if (compressed != null) setState(() => _newAvatar = File(compressed.path));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery permission required')));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final res = await WorkerService.updateProfile({
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'bio': _bioController.text.trim(),
    }, _newAvatar?.path);
    setState(() => _isSaving = false);

    if (mounted) {
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('full_name', _nameController.text.trim());
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

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
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                            clipBehavior: Clip.hardEdge,
                            child: _newAvatar != null 
                              ? Image.file(_newAvatar!, fit: BoxFit.cover)
                              : (_profilePicture.isNotEmpty 
                                  ? Image.network('https://works.kainuwa.africa/uploads/avatars/$_profilePicture', fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.person, color: theme.colorScheme.primary, size: 40))
                                  : Center(child: Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'W', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)))),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3)),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text('${_rating.toStringAsFixed(1)} ($_reviews Reviews)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Full Name', prefixIcon: const Icon(Icons.person_outline), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone_outlined), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  TextField(controller: _bioController, maxLines: 3, decoration: InputDecoration(labelText: 'Professional Bio', prefixIcon: const Icon(Icons.info_outline), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioManagerScreen())),
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.photo_library_rounded, color: Colors.blue, size: 20)),
                    title: const Text('Manage Portfolio Images', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: theme.colorScheme.primary),
                    value: isDark,
                    activeColor: theme.colorScheme.primary,
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
}
