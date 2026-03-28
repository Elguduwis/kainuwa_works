import 'package:flutter/material.dart';
import '../../services/worker_service.dart';

class WorkerPayoutMethodsScreen extends StatefulWidget {
  const WorkerPayoutMethodsScreen({super.key});

  @override
  State<WorkerPayoutMethodsScreen> createState() => _WorkerPayoutMethodsScreenState();
}

class _WorkerPayoutMethodsScreenState extends State<WorkerPayoutMethodsScreen> {
  bool _isLoading = true;
  List<dynamic> _methods = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await WorkerService.fetchPayoutMethods();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') _methods = data['methods'] ?? [];
      });
    }
  }

  Future<void> _deleteMethod(String methodId) async {
    setState(() => _isLoading = true);
    final res = await WorkerService.deletePayoutMethod(methodId);
    if (res['status'] == 'success') {
      _loadData();
    } else {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to delete'), backgroundColor: Colors.red));
    }
  }

  void _showAddBankSheet() async {
    setState(() => _isLoading = true);
    final banks = await WorkerService.fetchBanks();
    setState(() => _isLoading = false);

    if (banks.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load bank list.')));
      return;
    }

    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        List<dynamic> filteredBanks = List.from(banks);
        String? selectedBankCode;
        String? selectedBankName;
        bool isResolving = false;
        bool isSaving = false;
        String resolvedAccountName = '';
        String errorMessage = '';
        final accController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Bank Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    
                    if (selectedBankCode == null) ...[
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for your bank...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            filteredBanks = banks.where((b) => b['name'].toString().toLowerCase().contains(val.toLowerCase())).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredBanks.length,
                          itemBuilder: (context, index) {
                            final b = filteredBanks[index];
                            return ListTile(
                              title: Text(b['name']),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 16),
                              onTap: () {
                                setModalState(() {
                                  selectedBankCode = b['code'];
                                  selectedBankName = b['name'];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedBankName ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            GestureDetector(onTap: () => setModalState(() { selectedBankCode = null; resolvedAccountName = ''; }), child: const Icon(Icons.close_rounded, size: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Account Number', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: accController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        onChanged: (val) async {
                          if (val.length == 10) {
                            setModalState(() { isResolving = true; errorMessage = ''; resolvedAccountName = ''; });
                            final res = await WorkerService.resolveAccount(val, selectedBankCode!);
                            setModalState(() {
                              isResolving = false;
                              if (res['success'] == true) resolvedAccountName = res['account_name'];
                              else errorMessage = res['message'] ?? 'Account not found.';
                            });
                          } else {
                            setModalState(() => resolvedAccountName = '');
                          }
                        },
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: '0123456789',
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isResolving) const Center(child: CircularProgressIndicator())
                      else if (errorMessage.isNotEmpty) Text(errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      else if (resolvedAccountName.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Verified Account Name:', style: TextStyle(color: Colors.green, fontSize: 12)), const SizedBox(height: 4), Text(resolvedAccountName, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))])),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: (resolvedAccountName.isNotEmpty && !isSaving) ? () async {
                            setModalState(() => isSaving = true);
                            final res = await WorkerService.addPayoutMethod({'bank_name': selectedBankName!, 'bank_code': selectedBankCode!, 'account_number': accController.text.trim(), 'account_name': resolvedAccountName});
                            setModalState(() => isSaving = false);
                            if (res['status'] == 'success') {
                              Navigator.pop(context);
                              _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Bank Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
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
      appBar: AppBar(title: const Text('Payout Methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), backgroundColor: Colors.transparent),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _methods.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.account_balance_rounded, size: 64, color: isDark ? Colors.grey[800] : Colors.grey[300]), const SizedBox(height: 16), Text('No bank accounts linked', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey))]))
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: _methods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final m = _methods[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFF3F4F6)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.account_balance_rounded, color: theme.colorScheme.primary)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['bank_name'], style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                              const SizedBox(height: 4),
                              Text('${m['account_number']} - ${m['account_name']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Remove Bank?'),
                                content: const Text('Are you sure you want to remove this payout method?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () { Navigator.pop(ctx); _deleteMethod(m['id'].toString()); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Delete')),
                                ],
                              )
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBankSheet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Bank Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
