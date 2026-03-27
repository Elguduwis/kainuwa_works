import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/client_service.dart';
import '../../services/worker_service.dart';

class PortfolioManagerScreen extends StatefulWidget {
  const PortfolioManagerScreen({super.key});

  @override
  State<PortfolioManagerScreen> createState() => _PortfolioManagerScreenState();
}

class _PortfolioManagerScreenState extends State<PortfolioManagerScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<dynamic> _portfolio = [];

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    final userId = await WorkerService.getUserId();
    if (userId == null) return;

    final data = await ClientService.fetchWorkerProfile(userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _portfolio = data['portfolio'] ?? [];
        }
      });
    }
  }

  Future<void> _uploadNewImage() async {
    var photoStatus = await Permission.photos.request();
    var storageStatus = await Permission.storage.request();
    
    if (photoStatus.isGranted || storageStatus.isGranted) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isUploading = true);
        final compressed = await FlutterImageCompress.compressAndGetFile(picked.path, '${picked.path}_portfolio.jpg', quality: 60);
        
        if (compressed != null) {
          final res = await WorkerService.uploadPortfolioImage(compressed.path);
          if (mounted) {
            if (res['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded!'), backgroundColor: Colors.green));
              _loadPortfolio(); // Refresh grid
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
            }
          }
        }
        setState(() => _isUploading = false);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery permission required')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              if (_portfolio.isEmpty)
                const Center(child: Text('No images uploaded yet.', style: TextStyle(color: Colors.grey)))
              else
                GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
                  itemCount: _portfolio.length,
                  itemBuilder: (ctx, idx) {
                    final String imgUrl = _portfolio[idx]['image_path'] ?? '';
                    return Container(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.hardEdge,
                      child: imgUrl.isNotEmpty
                          ? Image.network('https://works.kainuwa.africa/uploads/portfolio/$imgUrl', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)))
                          : const Center(child: Icon(Icons.image, color: Colors.grey)), 
                    );
                  },
                ),
              if (_isUploading)
                Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadNewImage,
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text('Add Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
