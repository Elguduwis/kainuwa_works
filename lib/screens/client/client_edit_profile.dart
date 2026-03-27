import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/client_service.dart';

class ClientEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const ClientEditProfileScreen({super.key, required this.profileData});

  @override
  State<ClientEditProfileScreen> createState() => _ClientEditProfileScreenState();
}

class _ClientEditProfileScreenState extends State<ClientEditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;
  File? _newAvatar;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profileData['full_name'] ?? '';
    _phoneController.text = widget.profileData['phone'] ?? '';
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
    final res = await ClientService.updateProfile({
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, _newAvatar?.path);
    setState(() => _isSaving = false);

    if (mounted) {
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('full_name', _nameController.text.trim());
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String profilePicture = widget.profileData['profile_picture'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
      body: SingleChildScrollView(
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
                        : (profilePicture.isNotEmpty 
                            ? Image.network('https://works.kainuwa.africa/uploads/avatars/$profilePicture', fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.person, color: theme.colorScheme.primary, size: 40))
                            : Center(child: Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'C', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)))),
                    ),
                    Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3)), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Full Name', prefixIcon: const Icon(Icons.person_outline), filled: true, fillColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone_outlined), filled: true, fillColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
