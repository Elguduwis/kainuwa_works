import 'package:flutter/material.dart';
import '../../services/worker_service.dart';
import 'worker_chat.dart';

class WorkerBookingsScreen extends StatefulWidget {
  const WorkerBookingsScreen({super.key});

  @override
  State<WorkerBookingsScreen> createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends State<WorkerBookingsScreen> {
  bool _isLoading = true;
  List<dynamic> _active = [];
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is num) return amount.toDouble();
    return double.tryParse(amount.toString()) ?? 0.0;
  }

  Future<void> _loadData() async {
    final data = await WorkerService.fetchBookings();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _active = data['active_bookings'] ?? [];
          _history = data['history_bookings'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Jobs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [Tab(text: 'Active Jobs'), Tab(text: 'History')],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                _buildBookingList(_active, isActive: true, theme: theme),
                _buildBookingList(_history, isActive: false, theme: theme),
              ],
            ),
      ),
    );
  }

  Widget _buildBookingList(List<dynamic> list, {required bool isActive, required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;

    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 400,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isActive ? Icons.handyman_rounded : Icons.history_rounded, size: 64, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                const SizedBox(height: 16),
                Text(isActive ? 'No active jobs' : 'No past jobs', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final b = list[index];
          final parsedAmount = _parseAmount(b['amount']); 

          return GestureDetector(
            onTap: () {
              if (isActive) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerChatScreen(bookingId: b['id'].toString(), clientName: b['client_name'] ?? 'Client')));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey[800]! : Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b['category_name'] ?? 'Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          (b['status'] ?? '').toUpperCase(), 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(b['status'])),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 16, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                      const SizedBox(width: 6),
                      Text(b['client_name'] ?? 'Client', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF4B5563))),
                      if (isActive) ...[
                        const Spacer(),
                        Icon(Icons.chat_bubble_rounded, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Chat', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                          const SizedBox(width: 6),
                          Text(b['service_location'] == 'client_location' ? 'Home Service' : 'Shop Visit', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF4B5563), fontSize: 12)),
                        ],
                      ),
                      Text('₦${parsedAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'accepted': return Colors.teal;
      case 'cancelled': return Colors.red;
      case 'disputed': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
