import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/client_service.dart'; 
import '../../services/worker_service.dart';
import '../shared/dispute_screen.dart';

class WorkerChatScreen extends StatefulWidget {
  final String bookingId;
  final String clientName;

  const WorkerChatScreen({super.key, required this.bookingId, required this.clientName});

  @override
  State<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends State<WorkerChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  Timer? _pollingTimer;
  int _lastMessageId = 0;
  bool _isFetching = false;
  String _bookingStatus = 'pending';
  int _releaseRequested = 0;

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
        _releaseRequested = res['release_requested'] ?? 0;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canRequest = (_bookingStatus == 'in_progress' && _releaseRequested == 0);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Text(widget.clientName.isNotEmpty ? widget.clientName[0].toUpperCase() : 'C', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: canRequest ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: Icon(Icons.check_circle_outline_rounded, color: canRequest ? Colors.green : Colors.grey),
              tooltip: canRequest ? "Request Escrow Release" : "Release already requested or Job not active",
              onPressed: canRequest ? () async {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Job Completed?"),
                    content: const Text("Are you sure you want to request payment release from the client?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final res = await WorkerService.requestRelease(widget.bookingId);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res["message"]), backgroundColor: res["status"] == "success" ? Colors.green : Colors.red));
                          _fetchMessages(); // Update UI locks
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text("Yes, Request"),
                      ),
                    ],
                  ),
                );
              } : null,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'dispute') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => DisputeScreen(bookingId: widget.bookingId, role: 'worker')));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'dispute', child: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Raise Dispute', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ]
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
              ? const Center(child: Text('Chat with your client to agree on a price.', style: TextStyle(color: Colors.grey)))
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
