import 'package:flutter/material.dart';
import '../../services/worker_service.dart';

class WorkerAddBankScreen extends StatefulWidget {
  const WorkerAddBankScreen({super.key});

  @override
  State<WorkerAddBankScreen> createState() => _WorkerAddBankScreenState();
}

class _WorkerAddBankScreenState extends State<WorkerAddBankScreen> {
  bool _isLoadingBanks = true;
  bool _isResolving = false;
  bool _isSaving = false;
  
  List<dynamic> _banks = [];
  String? _selectedBankCode;
  String? _selectedBankName;
  
  final _accountNumberController = TextEditingController();
  String _resolvedAccountName = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    final banks = await WorkerService.fetchBanks();
    if (mounted) {
      setState(() {
        _banks = banks;
        _isLoadingBanks = false;
        if (_banks.isNotEmpty) {
          _selectedBankCode = _banks[0]['code'];
          _selectedBankName = _banks[0]['name'];
        }
      });
    }
  }

  Future<void> _resolveAccount() async {
    final accNum = _accountNumberController.text.trim();
    if (accNum.length != 10 || _selectedBankCode == null) {
      setState(() {
        _errorMessage = 'Enter a valid 10-digit account number.';
        _resolvedAccountName = '';
      });
      return;
    }

    setState(() {
      _isResolving = true;
      _errorMessage = '';
      _resolvedAccountName = '';
    });

    final res = await WorkerService.resolveAccount(accNum, _selectedBankCode!);
    
    if (mounted) {
      setState(() {
        _isResolving = false;
        if (res['success'] == true) {
          _resolvedAccountName = res['account_name'];
        } else {
          _errorMessage = res['message'] ?? 'Account not found.';
        }
      });
    }
  }

  Future<void> _saveAccount() async {
    if (_resolvedAccountName.isEmpty) return;

    setState(() => _isSaving = true);
    
    final res = await WorkerService.addPayoutMethod({
      'bank_name': _selectedBankName!,
      'bank_code': _selectedBankCode!,
      'account_number': _accountNumberController.text.trim(),
      'account_name': _resolvedAccountName,
    });

    setState(() => _isSaving = false);

    if (mounted) {
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank account saved!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to save account'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
      body: _isLoadingBanks 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedBankCode,
                      items: _banks.map<DropdownMenuItem<String>>((b) {
                        return DropdownMenuItem<String>(
                          value: b['code'].toString(),
                          child: Text(b['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBankCode = val;
                            _selectedBankName = _banks.firstWhere((b) => b['code'] == val)['name'];
                            _resolvedAccountName = '';
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Account Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  onChanged: (val) {
                    if (val.length == 10) _resolveAccount();
                    else setState(() => _resolvedAccountName = '');
                  },
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: '0123456789',
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isResolving)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage.isNotEmpty)
                  Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                else if (_resolvedAccountName.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Verified Account Name:', style: TextStyle(color: Colors.green, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(_resolvedAccountName, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: (_resolvedAccountName.isNotEmpty && !_isSaving) ? _saveAccount : null,
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Bank Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
