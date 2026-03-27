import 'package:flutter/material.dart';
import '../../services/client_service.dart';
import 'client_worker_profile.dart';

class ClientAllProvidersScreen extends StatefulWidget {
  const ClientAllProvidersScreen({super.key});

  @override
  State<ClientAllProvidersScreen> createState() => _ClientAllProvidersScreenState();
}

class _ClientAllProvidersScreenState extends State<ClientAllProvidersScreen> {
  bool _isLoading = true;
  List<dynamic> _providers = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    final data = await ClientService.fetchProviders(categoryId: '0');
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') _providers = data['providers'] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Browse All Providers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.transparent),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
              ? const Center(child: Text('No providers available right now.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _providers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    final String imageUrl = provider['profile_picture'] ?? '';
                    final double rating = double.tryParse(provider['average_rating'].toString()) ?? 0.0;
                    
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientWorkerProfileScreen(workerId: provider['id'].toString()))),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFF3F4F6)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                              clipBehavior: Clip.hardEdge,
                              child: imageUrl.isNotEmpty
                                  ? Image.network('https://works.kainuwa.africa/uploads/avatars/$imageUrl', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Center(child: Text(provider['full_name'].toString()[0].toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : theme.colorScheme.primary))))
                                  : Center(child: Text(provider['full_name'].toString()[0].toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : theme.colorScheme.primary))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(provider['full_name'] ?? 'Provider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                                  const SizedBox(height: 4),
                                  Text(provider['skills'] ?? 'General Services', style: TextStyle(color: isDark ? Colors.white : theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(children: [const Icon(Icons.star_rounded, color: Colors.orange, size: 14), const SizedBox(width: 4), Text('$rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : const Color(0xFF4B5563)))]),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
