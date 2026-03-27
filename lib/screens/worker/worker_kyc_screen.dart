import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/worker_service.dart';

class WorkerKycScreen extends StatefulWidget {
  const WorkerKycScreen({super.key});

  @override
  State<WorkerKycScreen> createState() => _WorkerKycScreenState();
}

class _WorkerKycScreenState extends State<WorkerKycScreen> {
  bool _isLoading = true;
  String _verificationStatus = 'unverified';
  String _selectedDocType = 'national_id';
  File? _docImage;
  File? _selfieImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final data = await WorkerService.fetchSettings();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _verificationStatus = data['profile']['verification_status'] ?? 'unverified';
        }
      });
    }
  }

  Future<void> _pickImage(bool isSelfie) async {
    var photoStatus = await Permission.photos.request();
    var storageStatus = await Permission.storage.request();
    var cameraStatus = await Permission.camera.request();
    
    if (photoStatus.isGranted || storageStatus.isGranted || cameraStatus.isGranted) {
      final source = isSelfie ? ImageSource.camera : ImageSource.gallery;
      final picked = await ImagePicker().pickImage(source: source);
      if (picked != null) {
        final compressed = await FlutterImageCompress.compressAndGetFile(picked.path, '${picked.path}_kyc.jpg', quality: 50);
        if (compressed != null) {
          setState(() {
            if (isSelfie) _selfieImage = File(compressed.path);
            else _docImage = File(compressed.path);
          });
        }
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions required.')));
    }
  }

  Future<void> _submitKyc() async {
    if (_docImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload both the ID and the selfie.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await WorkerService.uploadKyc(_selectedDocType, _docImage!.path, _selfieImage!.path);
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Submitted! Admin will review soon.'), backgroundColor: Colors.green));
        _checkStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildBodyContent(theme, isDark),
          ),
    );
  }

  Widget _buildBodyContent(ThemeData theme, bool isDark) {
    if (_verificationStatus == 'approved') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.verified_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Account Verified', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            Text('Your identity has been fully verified. No further action is required.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ],
        ),
      );
    }

    if (_verificationStatus == 'pending') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 80),
            const SizedBox(height: 16),
            const Text('Verification Pending', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            Text('Your documents are currently under review by an administrator. Please check back later.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [Icon(Icons.security_rounded, color: Colors.blue), SizedBox(width: 12), Expanded(child: Text('We require valid ID verification to ensure trust and safety across the Kainuwa platform.', style: TextStyle(color: Colors.blue, fontSize: 13)))]),
        ),
        const SizedBox(height: 24),
        
        const Text('Document Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[800]! : Colors.transparent)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedDocType,
              items: const [
                DropdownMenuItem(value: 'national_id', child: Text('National ID (NIN)')),
                DropdownMenuItem(value: 'voter_card', child: Text('Voter Card')),
                DropdownMenuItem(value: 'passport', child: Text('International Passport')),
              ],
              onChanged: (val) { if (val != null) setState(() => _selectedDocType = val); },
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text('Upload ID Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(false),
          child: Container(
            height: 150, width: double.infinity,
            decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)), borderRadius: BorderRadius.circular(16)),
            child: _docImage != null ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_docImage!, fit: BoxFit.cover)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_file_rounded, color: theme.colorScheme.primary, size: 32), const SizedBox(height: 8), Text('Tap to upload gallery image', style: TextStyle(color: theme.colorScheme.primary))]),
          ),
        ),
        const SizedBox(height: 24),

        const Text('Take a Selfie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(true),
          child: Container(
            height: 150, width: double.infinity,
            decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)), borderRadius: BorderRadius.circular(16)),
            child: _selfieImage != null ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_selfieImage!, fit: BoxFit.cover)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary, size: 32), const SizedBox(height: 8), Text('Tap to take a clear selfie', style: TextStyle(color: theme.colorScheme.primary))]),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitKyc,
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit for Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
