import 'package:flutter/material.dart';
import '../../services/client_service.dart';

class ClientWorkerProfileScreen extends StatefulWidget {
  final String workerId;

  const ClientWorkerProfileScreen({super.key, required this.workerId});

  @override
  State<ClientWorkerProfileScreen> createState() => _ClientWorkerProfileScreenState();
}

class _ClientWorkerProfileScreenState extends State<ClientWorkerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<dynamic> _categories = [];
  List<dynamic> _portfolio = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await ClientService.fetchWorkerProfile(widget.workerId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _profile = data['profile'];
          _categories = data['categories'] ?? [];
          _portfolio = data['portfolio'] ?? [];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Error loading profile')));
        }
      });
    }
  }

  void _showBookingSheet() {
    if (_profile == null || _categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot book right now.')));
      return;
    }

    String selectedCategoryId = _categories[0]['id'].toString();
    String locationPref = _profile!['service_preference'] ?? 'client_location';
    String selectedLocation = locationPref == 'both' ? 'client_location' : locationPref;
    final TextEditingController descController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('It is free to request. You will negotiate the price after they accept.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  const SizedBox(height: 24),
                  
                  const Text('Select Service', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCategoryId,
                        items: _categories.map<DropdownMenuItem<String>>((c) {
                          return DropdownMenuItem<String>(
                            value: c['id'].toString(),
                            child: Text(c['name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCategoryId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (locationPref == 'both') ...[
                    const Text('Service Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedLocation,
                          items: const [
                            DropdownMenuItem(value: 'client_location', child: Text('My Location (Home/Office)')),
                            DropdownMenuItem(value: 'provider_shop', child: Text('Provider\'s Shop')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedLocation = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('Describe what you need', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'E.g., My generator is leaking oil and won\'t start...',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        FocusScope.of(context).unfocus(); 
                        if (descController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the job.')));
                          return;
                        }
                        
                        setModalState(() => isSubmitting = true);
                        final res = await ClientService.createBooking({
                          'worker_id': widget.workerId,
                          'category_id': selectedCategoryId,
                          'service_location': selectedLocation,
                          'description': descController.text.trim(),
                        });
                        setModalState(() => isSubmitting = false);

                        if (res['status'] == 'success') {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Request Sent!')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to book')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Free Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent), body: const Center(child: CircularProgressIndicator()));
    }
    
    if (_profile == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Profile not found')));
    }

    final double rating = double.tryParse(_profile!['average_rating'].toString()) ?? 0.0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(24)),
                  child: Center(
                    child: Text(_profile!['full_name'].toString()[0].toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile!['full_name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 4),
                          Text('${rating.toStringAsFixed(1)} (${_profile!['total_reviews']} reviews)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${_profile!['experience_years']} years experience', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6))),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        Text('${_profile!['area'] ?? ''}, ${_profile!['state'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('About Provider', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text(_profile!['bio'] ?? 'No bio provided.', style: const TextStyle(color: Color(0xFF4B5563), height: 1.5)),
            const SizedBox(height: 32),

            const Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            if (_portfolio.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  children: [
                    Icon(Icons.image_not_supported_rounded, color: Color(0xFF9CA3AF), size: 32),
                    SizedBox(height: 8),
                    Text('No portfolio images uploaded', style: TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: _portfolio.length,
                itemBuilder: (ctx, idx) {
                  return Container(
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Icon(Icons.image, color: Colors.white)), 
                  );
                },
              ),
            const SizedBox(height: 80), 
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF4B5563)),
                onPressed: () {
                  // Reverted to standard SnackBar instruction!
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please request a service to start a chat.'))
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _showBookingSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Request Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
