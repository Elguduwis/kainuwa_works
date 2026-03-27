import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/client_service.dart';

class ClientChatScreen extends StatefulWidget {
  final String bookingId;
  final String workerName;

  const ClientChatScreen({super.key, required this.bookingId, required this.workerName});

  @override
  State<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends State<ClientChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  Timer? _pollingTimer;
  int _lastMessageId = 0;
  bool _isFetching = false;
  bool _isFunding = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _fetchMessages() async {
    if (_isFetching) return;
    _isFetching = true;

    final res = await ClientService.fetchChatMessages(widget.bookingId, _lastMessageId.toString());
    
    if (mounted && res['status'] == 'success') {
      final newMessages = res['messages'] as List;
      if (newMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(newMessages);
          _lastMessageId = newMessages.last['id'];
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    }
    _isFetching = false;
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    FocusScope.of(context).unfocus();

    final res = await ClientService.sendChatMessage(widget.bookingId, text);
    if (res['status'] == 'success') {
      _fetchMessages(); 
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to send')));
    }
  }

  // ESCROW LOGIC MODAL
  void _showEscrowDialog() {
    final TextEditingController amountController = TextEditingController();

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.shield_rounded, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fund Escrow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            Text('Lock in the agreed price to start the job.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Agreed Price (₦)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 15000',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.payments_rounded, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isFunding ? null : () async {
                        final amount = amountController.text.trim();
                        if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
                          return;
                        }
                        
                        setModalState(() => _isFunding = true);
                        FocusScope.of(context).unfocus();
                        
                        final res = await ClientService.fundEscrow(widget.bookingId, amount);
                        
                        setModalState(() => _isFunding = false);

                        if (res['status'] == 'success') {
                          Navigator.pop(context); // Close sheet
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isFunding 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Lock Funds Securely', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(widget.workerName[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.workerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.shield_rounded, color: Colors.green),
              tooltip: 'Fund Escrow',
              onPressed: _showEscrowDialog,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.task_alt_rounded, color: Colors.blue),
              tooltip: "Approve & Release Funds",
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Release Escrow?"),
                    content: const Text("Are you completely satisfied with the work? This action is irreversible and will pay the provider immediately."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final res = await ClientService.releaseEscrow(widget.bookingId);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res["message"] ?? "Released"), backgroundColor: res["status"] == "success" ? Colors.green : Colors.red));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        child: const Text("Approve Payment"),
                      ),
                    ],
                  ),
                );
              },

            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
              ? const Center(child: Text('Start the negotiation!', style: TextStyle(color: Color(0xFF9CA3AF))))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['is_mine'] == true;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isMe ? theme.colorScheme.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 20),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1F2937), fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(msg['time'], style: TextStyle(color: isMe ? Colors.white70 : const Color(0xFF9CA3AF), fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
