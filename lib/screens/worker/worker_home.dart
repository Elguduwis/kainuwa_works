import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/worker_service.dart';
import 'worker_bookings.dart';
import 'worker_wallet.dart';
import 'worker_settings.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isProcessingAction = false;
  
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _wallet;
  List<dynamic> _requests = [];
  int _activeJobs = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final data = await WorkerService.fetchDashboard();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _profile = data['profile'];
          _wallet = data['wallet'];
          _requests = data['pending_requests'] ?? [];
          _activeJobs = data['active_jobs_count'] ?? 0;
        }
      });
    }
  }

  Future<void> _handleBookingAction(String bookingId, String status) async {
    setState(() => _isProcessingAction = true);
    final res = await WorkerService.updateBookingStatus(bookingId, status);
    
    if (mounted) {
      setState(() => _isProcessingAction = false);
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Success!'), backgroundColor: status == 'accepted' ? Colors.green : Colors.black87));
        _loadDashboard(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Action failed'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _toggleAvailability(String currentStatus) async {
    final newStatus = currentStatus == 'available' ? 'busy' : 'available';
    setState(() => _isProcessingAction = true);
    final res = await WorkerService.updateAvailability(newStatus);
    setState(() => _isProcessingAction = false);
    
    if (res['status'] == 'success') {
      _loadDashboard();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to update availability')));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildHomeContent(theme, isDark),
      const WorkerBookingsScreen(),
      const WorkerWalletScreen(),
      const WorkerSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : Stack(
                children: [
                  pages[_selectedIndex],
                  if (_isProcessingAction)
                    Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.handyman_rounded), label: 'My Jobs'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(ThemeData theme, bool isDark) {
    final String name = _profile?['full_name'] ?? 'Provider';
    final String firstName = name.split(' ')[0];
    final String status = _profile?['availability_status'] ?? 'offline';
    final bool isAvailable = status == 'available';
    final double balance = double.tryParse(_wallet?['balance']?.toString() ?? '0') ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, $firstName', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _toggleAvailability(status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isAvailable ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3))
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: isAvailable ? Colors.green : Colors.orange, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(isAvailable ? 'Available (Tap to hide)' : 'Busy (Tap to work)', style: TextStyle(fontSize: 12, color: isAvailable ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _onItemTapped(3),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(firstName.isNotEmpty ? firstName[0].toUpperCase() : 'W', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(2),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 24),
                          const SizedBox(height: 12),
                          const Text('Available Earnings', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('₦${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.handyman_rounded, color: theme.colorScheme.primary, size: 24),
                          const SizedBox(height: 12),
                          Text('Active Jobs', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('$_activeJobs', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Incoming Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
                if (_requests.isNotEmpty)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: Text('${_requests.length} New', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),

            if (_requests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFF3F4F6))),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, color: isDark ? Colors.grey[600] : const Color(0xFFD1D5DB), size: 48),
                    const SizedBox(height: 16),
                    Text('No new requests right now', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  final String bookingId = req['id'].toString();
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(req['category_name'] ?? 'Service Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                            const Text('FREE REQUEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 16, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(req['client_name'] ?? 'Client', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : const Color(0xFF4B5563))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(req['service_location'] == 'client_location' ? 'Home Service' : 'Shop Visit', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : const Color(0xFF4B5563))),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6))),
                        Text(req['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280))),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isProcessingAction ? null : () => _handleBookingAction(bookingId, 'declined'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isProcessingAction ? null : () => _handleBookingAction(bookingId, 'accepted'),
                                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: const Text('Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
