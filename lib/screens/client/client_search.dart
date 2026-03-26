import 'package:flutter/material.dart';
import '../../services/client_service.dart';
import 'client_worker_profile.dart';

class ClientSearchScreen extends StatefulWidget {
  final String initialQuery;
  final String categoryId;
  final String categoryName;

  const ClientSearchScreen({
    super.key, 
    this.initialQuery = '', 
    this.categoryId = '0',
    this.categoryName = 'Search Providers',
  });

  @override
  State<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends State<ClientSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _providers = [];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final data = await ClientService.fetchProviders(
      query: _searchController.text.trim(),
      categoryId: widget.categoryId,
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _providers = data['providers'] ?? [];
        } else {
          _providers = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialQuery.isNotEmpty ? 'Results for "${widget.initialQuery}"' : widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search Bar Area
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'Search for providers...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF9CA3AF)),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch();
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Results Area
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _providers.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _providers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildProviderCard(_providers[index], theme);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 24),
          const Text('No providers found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          const Text('Try adjusting your search terms.', style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider, ThemeData theme) {
    final double rating = double.tryParse(provider['average_rating'].toString()) ?? 0.0;
    final int reviews = int.tryParse(provider['total_reviews'].toString()) ?? 0;
    
    // Status Logic
    final String status = provider['availability_status'] ?? 'offline';
    final Color statusColor = status == 'available' ? Colors.green : (status == 'busy' ? Colors.orange : Colors.grey);

    // Location Formatting
    final List<String> locParts = [];
    if (provider['area'] != null && provider['area'].toString().isNotEmpty) locParts.add(provider['area']);
    if (provider['lga'] != null && provider['lga'].toString().isNotEmpty) locParts.add(provider['lga']);
    if (provider['state'] != null && provider['state'].toString().isNotEmpty) locParts.add(provider['state']);
    final String locationString = locParts.isNotEmpty ? locParts.join(', ') : 'Location not specified';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    provider['full_name'].toString()[0].toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            provider['full_name'] ?? 'Provider',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                        const SizedBox(width: 4),
                        Text('($reviews reviews)', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF9CA3AF), size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationString,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Skills', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 2),
                    Text(
                      provider['skills'] ?? 'General Services',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening profile for ${provider['full_name']}...')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
