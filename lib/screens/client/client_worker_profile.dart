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
    
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('It is free to request. You will negotiate the price after they accept.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  
                  const Text('Select Service', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCategoryId,
                        items: _categories.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(value: c['id'].toString(), child: Text(c['name']))).toList(),
                        onChanged: (val) { if (val != null) setModalState(() => selectedCategoryId = val); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (locationPref == 'both') ...[
                    const Text('Service Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedLocation,
                          items: const [
                            DropdownMenuItem(value: 'client_location', child: Text('My Location (Home/Office)')),
                            DropdownMenuItem(value: 'provider_shop', child: Text('Provider\'s Shop')),
                          ],
                          onChanged: (val) { if (val != null) setModalState(() => selectedLocation = val); },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ADDED: Date and Time Picker
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                                if (date != null) setModalState(() => selectedDate = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                                child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey), const SizedBox(width: 8), Text(selectedDate != null ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}" : "Select Date", style: TextStyle(color: selectedDate != null ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey))]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (time != null) setModalState(() => selectedTime = time);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                                child: Row(children: [const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey), const SizedBox(width: 8), Text(selectedTime != null ? selectedTime!.format(context) : "Select Time", style: TextStyle(color: selectedTime != null ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey))]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('Describe what you need', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'E.g., My generator is leaking oil and won\'t start...',
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        FocusScope.of(context).unfocus(); 
                        if (descController.text.trim().isEmpty || selectedDate == null || selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a description, date, and time.')));
                          return;
                        }
                        
                        setModalState(() => isSubmitting = true);
                        
                        // Format the date for SQL
                        final String sqlDateTime = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')} ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00";

                        final res = await ClientService.createBooking({
                          'worker_id': widget.workerId,
                          'category_id': selectedCategoryId,
                          'service_location': selectedLocation,
                          'description': descController.text.trim(),
                          'scheduled_date': sqlDateTime
                        });
                        setModalState(() => isSubmitting = false);

                        if (res['status'] == 'success') {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to book'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Free Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent), body: const Center(child: CircularProgressIndicator()));
    if (_profile == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Profile not found')));

    final double rating = double.tryParse(_profile!['average_rating'].toString()) ?? 0.0;
    final String imageUrl = _profile!['profile_picture'] ?? '';
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(24)),
                  clipBehavior: Clip.hardEdge,
                  child: imageUrl.isNotEmpty
                      ? Image.network('https://works.kainuwa.africa/uploads/avatars/$imageUrl', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Center(child: Text(_profile!['full_name'].toString()[0].toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))))
                      : Center(child: Text(_profile!['full_name'].toString()[0].toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile!['full_name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
                      const SizedBox(height: 4),
                      Row(children: [const Icon(Icons.star_rounded, color: Colors.orange, size: 18), const SizedBox(width: 4), Text('${rating.toStringAsFixed(1)} (${_profile!['total_reviews']} reviews)', style: const TextStyle(fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 4),
                      Text('${_profile!['experience_years']} years experience', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFF3F4F6))),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${_profile!['area'] ?? ''}, ${_profile!['state'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text('About Provider', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 8),
            Text(_profile!['bio'] ?? 'No bio provided.', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF4B5563), height: 1.5)),
            const SizedBox(height: 32),

            Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 16),
            if (_portfolio.isEmpty)
              Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16)), child: const Column(children: [Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 32), SizedBox(height: 8), Text('No portfolio images uploaded', style: TextStyle(color: Colors.grey))]))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: _portfolio.length,
                itemBuilder: (ctx, idx) {
                  final String imgUrl = _portfolio[idx]['image_path'] ?? '';
                  return Container(decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(16)), clipBehavior: Clip.hardEdge, child: imgUrl.isNotEmpty ? Image.network('https://works.kainuwa.africa/uploads/portfolio/$imgUrl', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white))) : const Center(child: Icon(Icons.image, color: Colors.white)));
                },
              ),
            const SizedBox(height: 80), 
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
        child: Row(
          children: [
            Container(decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)), child: IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please request a service to start a chat.'))))),
            const SizedBox(width: 16),
            Expanded(child: SizedBox(height: 56, child: ElevatedButton(onPressed: _showBookingSheet, style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Request Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))),
          ],
        ),
      ),
    );
  }
}
