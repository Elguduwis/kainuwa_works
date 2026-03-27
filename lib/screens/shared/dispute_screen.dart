import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/client_service.dart';
import '../../services/worker_service.dart';

class DisputeScreen extends StatefulWidget {
  final String bookingId;
  final String role; // 'client' or 'worker'

  const DisputeScreen({super.key, required this.bookingId, required this.role});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final TextEditingController _reasonController = TextEditingController();
  File? _imageFile;
  bool _isSubmitting = false;

  Future<void> _pickAndCompressImage() async {
    // Request permission for Android 13+ (Photos) and Older (Storage)
    var photoStatus = await Permission.photos.request();
    var storageStatus = await Permission.storage.request();
    
    if (photoStatus.isGranted || storageStatus.isGranted) {
      final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      
      if (picked != null) {
        setState(() => _isSubmitting = true); // Show loading during compression
        final targetPath = '${picked.path}_compressed.jpg';
        
        var compressedFile = await FlutterImageCompress.compressAndGetFile(
          picked.path, 
          targetPath, 
          quality: 60, // Compress heavily to save server storage
        );
        
        setState(() {
          _isSubmitting = false;
          if (compressedFile != null) _imageFile = File(compressedFile.path);
        });
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied to access gallery.')));
    }
  }

  void _submitDispute() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please explain the issue.')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    Map<String, dynamic> res;
    if (widget.role == 'client') {
      res = await ClientService.raiseDispute(widget.bookingId, reason, _imageFile?.path);
    } else {
      res = await WorkerService.raiseDispute(widget.bookingId, reason, _imageFile?.path);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to chat
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Raise Dispute', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(child: Text('Raising a dispute will freeze the Escrow funds. Admin will review the chat logs and evidence to mediate.', style: TextStyle(color: Colors.red, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Reason for Dispute', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Explain exactly what went wrong...',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Photographic Evidence (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickAndCompressImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: theme.colorScheme.primary, size: 32),
                          const SizedBox(height: 8),
                          Text('Tap to upload a compressed photo', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDispute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Dispute & Freeze Escrow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
