import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/client_service.dart';
import '../shared/dispute_screen.dart';

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
  String _bookingStatus = 'pending';

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
      _scrollController.animateTo(_scrollController.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _fetchMessages() async {
    if (_isFetching) return;
    _isFetching = true;

    final res = await ClientService.fetchChatMessages(widget.bookingId, _lastMessageId.toString());
    
    if (mounted && res['status'] == 'success') {
      final newMessages = res['messages'] as List;
      setState(() {
        _bookingStatus = res['booking_status'] ?? 'pending';
        if (newMessages.isNotEmpty) {
          _messages.addAll(newMessages);
          _lastMessageId = newMessages.last['id'];
        }
      });
      if (newMessages.isNotEmpty) Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
    _isFetching = false;
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    FocusScope.of(context).unfocus();
    final res = await ClientService.sendChatMessage(widget.bookingId, text);
    if (res['status'] == 'success') _fetchMessages(); 
  }

  void _showEscrowDialog() {
    if (_bookingStatus == 'in_progress' || _bookingStatus == 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds are already locked in Escrow for this job.')));
      return;
    }
    
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.shield_rounded, color: Colors.green)),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Fund Escrow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('Lock in the agreed price to start the job.', style: TextStyle(color: Colors.grey, fontSize: 13))])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Agreed Price (₦)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'e.g. 15000', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.payments_rounded, color: Colors.grey))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _isFunding ? null : () async {
                        final amount = amountController.text.trim();
                        if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) return;
                        setModalState(() => _isFunding = true);
                        final res = await ClientService.fundEscrow(widget.bookingId, amount);
                        setModalState(() => _isFunding = false);
                        if (res['status'] == 'success') {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.green));
                          _fetchMessages(); // Triggers UI lock
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: _isFunding ? const CircularProgressIndicator(color: Colors.white) : const Text('Lock Funds Securely', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final isEscrowFunded = (_bookingStatus == 'in_progress' || _bookingStatus == 'completed');

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Text(widget.workerName[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.workerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: isEscrowFunded ? Colors.grey.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: Icon(isEscrowFunded ? Icons.lock_rounded : Icons.shield_rounded, color: isEscrowFunded ? Colors.grey : Colors.green),
              tooltip: isEscrowFunded ? 'Escrow Funded' : 'Fund Escrow',
              onPressed: _showEscrowDialog,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'dispute') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => DisputeScreen(bookingId: widget.bookingId, role: 'client')));
              } else if (value == 'release') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Release Escrow?"),
                    content: const Text("Are you completely satisfied with the work?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
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
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'release', child: Row(children: [Icon(Icons.task_alt_rounded, color: Colors.blue), SizedBox(width: 8), Text('Release Funds')])),
              const PopupMenuItem<String>(value: 'dispute', child: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Raise Dispute', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
              ? const Center(child: Text('Start the negotiation!', style: TextStyle(color: Colors.grey)))
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
                          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface,
                          borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(isMe ? 20 : 0), bottomRight: Radius.circular(isMe ? 0 : 20)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(msg['time'], style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(backgroundColor: theme.colorScheme.primary, child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
