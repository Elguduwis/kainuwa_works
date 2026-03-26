import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/client_service.dart';
import 'web_dashboard_screen.dart';

class ClientWalletScreen extends StatefulWidget {
  const ClientWalletScreen({super.key});

  @override
  State<ClientWalletScreen> createState() => _ClientWalletScreenState();
}

class _ClientWalletScreenState extends State<ClientWalletScreen> {
  bool _isLoading = true;
  double _balance = 0.0;
  double _escrow = 0.0;
  List<dynamic> _transactions = [];

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
    final data = await ClientService.fetchWallet();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _balance = _parseAmount(data['wallet']['balance']);
          _escrow = _parseAmount(data['wallet']['escrow_balance']);
          _transactions = data['transactions'] ?? [];
        }
      });
    }
  }

  // The Secure Architecture Trigger
  void _startTopUpProcess() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    
    // Construct the secure auth URL targeting the web wallet page
    final authUrl = 'https://works.kainuwa.africa/api/mobile/webview_auth.php?user_id=$userId&redirect=/client/wallet.php';
    
    // Open the WebView and WAIT for the user to finish and close it
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebDashboardScreen(url: authUrl, title: 'Fund Wallet via Paystack'),
      ),
    );
    
    // Immediately refresh the native data when they return
    if (mounted) {
      setState(() => _isLoading = true);
      _loadData(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Escrow Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.transparent),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            color: theme.colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Main Balance', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('₦${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                              child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary, size: 28),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFF374151), height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 16),
                                SizedBox(width: 6),
                                Text('Locked in Escrow', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                              ],
                            ),
                            Text('₦${_escrow.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _startTopUpProcess,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Fund Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                  const SizedBox(height: 16),
                  
                  if (_transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No transactions yet.', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final isDeposit = tx['type'] == 'deposit' || tx['type'] == 'refund';
                        final parsedAmount = _parseAmount(tx['amount']); 
                        
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            child: Icon(isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isDeposit ? Colors.green : Colors.red),
                          ),
                          title: Text(tx['description'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(tx['status']?.toUpperCase() ?? 'PENDING', style: TextStyle(fontSize: 10, color: tx['status'] == 'successful' ? Colors.green : Colors.orange)),
                          trailing: Text(
                            '${isDeposit ? '+' : '-'}₦${parsedAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDeposit ? Colors.green : Colors.red),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }
}
