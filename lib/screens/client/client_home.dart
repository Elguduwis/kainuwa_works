import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/client_service.dart';
import '../../utils/icon_helper.dart';
import 'client_bookings.dart';
import 'client_wallet.dart';
import 'client_settings.dart';
import 'client_search.dart';
import 'client_categories.dart';
import 'client_all_providers.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'Client';
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('full_name') ?? 'Client';
      _userName = _userName.split(' ')[0];
    });
  }

  Future<void> _loadCategories() async {
    final data = await ClientService.fetchCategories();
    if (mounted) {
      setState(() {
        _isLoadingCategories = false;
        if (data['status'] == 'success') {
          _categories = data['categories'] ?? [];
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientSearchScreen(initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildHomeContent(theme, isDark),
      const ClientBookingsScreen(),
      const ClientWalletScreen(),
      const ClientSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
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
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadCategories,
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
                    Text('Good evening, $_userName', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Need a service?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.5)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _onItemTapped(3),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'C', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: TextField(
                textInputAction: TextInputAction.search,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) _navigateToSearch(value.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Search for plumbers, electricians...',
                  hintStyle: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF), fontSize: 15),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientCategoriesScreen())),
                  child: Text('See All', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _isLoadingCategories 
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    ..._categories.take(7).map((cat) => _buildCategoryItem(IconHelper.getIcon(cat['icon']), cat['name'], theme, cat['id'].toString(), isDark)),
                    _buildMoreItem(theme, isDark),
                  ],
                ),
            const SizedBox(height: 32),

            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientAllProvidersScreen())),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Browse All Providers', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('View all registered professionals.', style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF6B7280), fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, ThemeData theme, String categoryId, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ClientSearchScreen(categoryId: categoryId, categoryName: label)));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : const Color(0xFF4B5563)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMoreItem(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientCategoriesScreen())),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280), size: 24),
          ),
          const SizedBox(height: 8),
          Text('More', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : const Color(0xFF4B5563)), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }
}
