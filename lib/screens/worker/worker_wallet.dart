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
  List<dynamic> _payoutMethods = [];

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
    final payoutData = await WorkerService.fetchPayoutMethods();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _balance = _parseAmount(data['wallet']['balance']);
          _transactions = data['transactions'] ?? [];
        }
        if (payoutData['status'] == 'success') {
          _payoutMethods = payoutData['methods'] ?? [];
        }
      });
    }
  }

  void _showWithdrawalSheet() {
    if (_payoutMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a bank account in your Web Dashboard first.')));
      return;
    }

    final TextEditingController amountController = TextEditingController();
    String selectedBank = "${_payoutMethods[0]['bank_name']} - ${_payoutMethods[0]['account_number']}";
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Withdraw Earnings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Available: NGN ${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  const Text('Amount to Withdraw (NGN)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Minimum 1000',
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Select Bank Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedBank,
                        items: _payoutMethods.map<DropdownMenuItem<String>>((b) {
                          final label = "${b['bank_name']} - ${b['account_number']}";
                          return DropdownMenuItem<String>(value: label, child: Text(label));
                        }).toList(),
                        onChanged: (val) { if (val != null) setModalState(() => selectedBank = val); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        FocusScope.of(context).unfocus();
                        final amount = amountController.text.trim();
                        
                        if (amount.isEmpty || double.tryParse(amount) == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount.')));
                          return;
                        }
                        
                        setModalState(() => isSubmitting = true);
                        final res = await WorkerService.requestWithdrawal(amount, selectedBank);
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
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Request Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        Text('NGN ${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _showWithdrawalSheet,
                      icon: const Icon(Icons.account_balance_rounded),
                      label: const Text('Withdraw Funds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white : Colors.black87, foregroundColor: isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  
                  if (_transactions.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.only(top: 40.0), child: Text('No transactions yet.', style: TextStyle(color: Colors.grey))))
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
                          leading: CircleAvatar(backgroundColor: isDeposit ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), child: Icon(isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isDeposit ? Colors.green : Colors.orange)),
                          title: Text(tx['description'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(tx['status']?.toUpperCase() ?? 'PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tx['status'] == 'successful' ? Colors.green : Colors.orange)),
                          trailing: Text('${isDeposit ? '+' : '-'}NGN ${parsedAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDeposit ? Colors.green : Colors.orange)),
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
