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
        if (data['status'] == 'success') _portfolio = data['portfolio'] ?? [];
      });
    }
  }

  Future<void> _deleteImage(String imageId) async {
    setState(() => _isUploading = true);
    final res = await WorkerService.deletePortfolioImage(imageId);
    if (mounted) {
      setState(() => _isUploading = false);
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image deleted.'), backgroundColor: Colors.green));
        _loadPortfolio();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to delete'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _uploadNewImages() async {
    var photoStatus = await Permission.photos.request();
    var storageStatus = await Permission.storage.request();
    
    if (photoStatus.isGranted || storageStatus.isGranted) {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() => _isUploading = true);
        int successCount = 0;
        for (var file in pickedFiles) {
          final targetPath = '${file.path}_comp_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final compressed = await FlutterImageCompress.compressAndGetFile(file.path, targetPath, quality: 40, minWidth: 800, minHeight: 800);
          if (compressed != null) {
            final res = await WorkerService.uploadPortfolioImage(compressed.path);
            if (res['status'] == 'success') successCount++;
          }
        }
        if (mounted) {
          setState(() => _isUploading = false);
          if (successCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully uploaded $successCount images!'), backgroundColor: Colors.green));
            _loadPortfolio();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload images.'), backgroundColor: Colors.red));
          }
        }
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery permission required')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('My Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.transparent),
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
                    final String imgId = _portfolio[idx]['id'].toString();
                    return Stack(
                      children: [
                        Container(
                          width: double.infinity, height: double.infinity,
                          decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(16)),
                          clipBehavior: Clip.hardEdge,
                          child: imgUrl.isNotEmpty
                              ? Image.network('https://works.kainuwa.africa/uploads/portfolio/$imgUrl', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)))
                              : const Center(child: Icon(Icons.image, color: Colors.grey)), 
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Image?'),
                                  content: const Text('This will permanently remove this image from your public portfolio.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () { Navigator.pop(context); _deleteImage(imgId); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
                                  ],
                                )
                              );
                            },
                            child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.delete_rounded, color: Colors.white, size: 16)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              if (_isUploading) Container(color: Colors.black.withOpacity(0.6), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadNewImages,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: const Text('Add Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
