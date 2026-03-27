import 'package:flutter/material.dart';
import '../../services/worker_service.dart';

class WorkerWalletScreen extends StatefulWidget {
  const WorkerWalletScreen({super.key});

  @override
  State<WorkerWalletScreen> createState() => _WorkerWalletScreenState();
}

class _WorkerWalletScreenState extends State<WorkerWalletScreen> {
  bool _isLoading = true;
  double _balance = 0.0;
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
    final data = await WorkerService.fetchWallet();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _balance = _parseAmount(data['wallet']['balance']);
          _transactions = data['transactions'] ?? [];
        }
      });
    }
  }

  void _showWithdrawalSheet() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController bankController = TextEditingController();
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
                  const Text('Withdraw Earnings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Available: ₦${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  const Text('Amount to Withdraw (₦)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Minimum ₦1000',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Bank Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bankController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Access Bank - 0123456789',
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
                        final amount = amountController.text.trim();
                        final bank = bankController.text.trim();
                        
                        if (amount.isEmpty || bank.isEmpty || double.tryParse(amount) == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields correctly.')));
                          return;
                        }
                        
                        setModalState(() => isSubmitting = true);
                        final res = await WorkerService.requestWithdrawal(amount, bank);
                        setModalState(() => isSubmitting = false);

                        if (res['status'] == 'success') {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.green));
                          setState(() => _isLoading = true);
                          _loadData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Request Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.transparent),
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
                      gradient: const LinearGradient(colors: [Color(0xFF7351FF), Color(0xFF5A3BE0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available for Withdrawal', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('₦${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _showWithdrawalSheet,
                      icon: const Icon(Icons.account_balance_rounded),
                      label: const Text('Withdraw Funds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                  const SizedBox(height: 16),
                  
                  if (_transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Text('No transactions yet.', style: TextStyle(color: Color(0xFF6B7280))),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final isDeposit = tx['type'] == 'deposit' || tx['type'] == 'escrow_release';
                        final parsedAmount = _parseAmount(tx['amount']); 
                        
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isDeposit ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            child: Icon(isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isDeposit ? Colors.green : Colors.orange),
                          ),
                          title: Text(tx['description'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(tx['status']?.toUpperCase() ?? 'PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tx['status'] == 'successful' ? Colors.green : Colors.orange)),
                          trailing: Text(
                            '${isDeposit ? '+' : '-'}₦${parsedAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDeposit ? Colors.green : Colors.orange),
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
