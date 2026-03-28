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
    
    // FIXED: Call the dedicated StatefulWidget so keyboard opening doesn't reset variables
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddBankBottomSheet(banks: banks),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      _loadData();
    }
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

// -----------------------------------------------------------------
// DEDICATED BOTTOM SHEET CLASS TO PREVENT KEYBOARD RESET BUGS
// -----------------------------------------------------------------
class _AddBankBottomSheet extends StatefulWidget {
  final List<dynamic> banks;
  const _AddBankBottomSheet({required this.banks});

  @override
  State<_AddBankBottomSheet> createState() => _AddBankBottomSheetState();
}

class _AddBankBottomSheetState extends State<_AddBankBottomSheet> {
  List<dynamic> _filteredBanks = [];
  String? _selectedBankCode;
  String? _selectedBankName;
  bool _isResolving = false;
  bool _isSaving = false;
  String _resolvedAccountName = '';
  String _errorMessage = '';
  final _accController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredBanks = List.from(widget.banks);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Bank Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            
            if (_selectedBankCode == null) ...[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for your bank...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  setState(() {
                    _filteredBanks = widget.banks.where((b) => b['name'].toString().toLowerCase().contains(val.toLowerCase())).toList();
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredBanks.length,
                  itemBuilder: (context, index) {
                    final b = _filteredBanks[index];
                    return ListTile(
                      title: Text(b['name']),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 16),
                      onTap: () {
                        setState(() {
                          _selectedBankCode = b['code'];
                          _selectedBankName = b['name'];
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
                    Text(_selectedBankName ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    GestureDetector(onTap: () => setState(() { _selectedBankCode = null; _resolvedAccountName = ''; }), child: const Icon(Icons.close_rounded, size: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Account Number', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _accController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                onChanged: (val) async {
                  if (val.length == 10) {
                    setState(() { _isResolving = true; _errorMessage = ''; _resolvedAccountName = ''; });
                    final res = await WorkerService.resolveAccount(val, _selectedBankCode!);
                    setState(() {
                      _isResolving = false;
                      if (res['success'] == true) _resolvedAccountName = res['account_name'];
                      else _errorMessage = res['message'] ?? 'Account not found.';
                    });
                  } else {
                    setState(() => _resolvedAccountName = '');
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
              if (_isResolving) const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty) Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              else if (_resolvedAccountName.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Verified Account Name:', style: TextStyle(color: Colors.green, fontSize: 12)), const SizedBox(height: 4), Text(_resolvedAccountName, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))])),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: (_resolvedAccountName.isNotEmpty && !_isSaving) ? () async {
                    setState(() => _isSaving = true);
                    final res = await WorkerService.addPayoutMethod({'bank_name': _selectedBankName!, 'bank_code': _selectedBankCode!, 'account_number': _accController.text.trim(), 'account_name': _resolvedAccountName});
                    setState(() => _isSaving = false);
                    if (mounted) {
                      if (res['status'] == 'success') {
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
                      }
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Bank Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
