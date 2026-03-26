import 'package:flutter/material.dart';
import '../../services/client_service.dart';

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

  Future<void> _loadData() async {
    final data = await ClientService.fetchWallet();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _balance = (data['wallet']['balance'] as num).toDouble();
          _escrow = (data['wallet']['escrow_balance'] as num).toDouble();
          _transactions = data['transactions'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escrow Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
      ),
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
                  // Dual Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F2937), Color(0xFF111827)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
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

                  // Top Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paystack Top-up initiating...')));
                      },
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
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No transactions yet.', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
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
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            child: Icon(
                              isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isDeposit ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(tx['description'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(tx['status']?.toUpperCase() ?? 'PENDING', style: TextStyle(fontSize: 10, color: tx['status'] == 'successful' ? Colors.green : Colors.orange)),
                          trailing: Text(
                            '${isDeposit ? '+' : '-'}₦${(tx['amount'] as num).toStringAsFixed(2)}',
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
