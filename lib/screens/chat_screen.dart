import 'package:flutter/material.dart';
import '../models/help_request.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final HelpRequest request;
  final String otherUserName;
  final IconData otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.request,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final String _currentUserId = 'currentUser';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildRequestSummary(context),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyChat(context)
                : _buildMessageList(context),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(BuildContext context) {
    final textSecondary = AppTheme.getTextSecondary(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Mulai percakapan', style: TextStyle(color: textSecondary)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return AppBar(
      backgroundColor: cardColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Icon(widget.otherUserAvatar, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                Text('Online', style: TextStyle(fontSize: 12, color: AppTheme.accentColor)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(icon: Icon(Icons.call_outlined, color: textPrimary), onPressed: () {}),
        IconButton(icon: Icon(Icons.more_vert, color: textPrimary), onPressed: () {}),
      ],
    );
  }

  Widget _buildRequestSummary(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.request.categoryIcon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.request.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(widget.request.priceDisplay, style: TextStyle(fontSize: 12, color: AppTheme.accentColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Negosiasi', style: TextStyle(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;
        return _buildMessageBubble(context, message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, bool isMe) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(widget.otherUserAvatar, size: 16, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.message, style: TextStyle(color: isMe ? Colors.white : textPrimary, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(_formatTime(message.timestamp), style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final bgColor = AppTheme.getBackgroundColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
              onPressed: () => _showQuickActions(),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(color: textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.getTextSecondary(context).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(Icons.attach_money, 'Tawar Harga', AppTheme.accentColor, textPrimary, () {
                  Navigator.pop(context);
                  _showPriceOfferDialog();
                }),
                _buildQuickAction(Icons.location_on, 'Share Lokasi', AppTheme.primaryColor, textPrimary, () {
                  Navigator.pop(context);
                  _sendLocationMessage();
                }),
                _buildQuickAction(Icons.check_circle, 'Deal!', const Color(0xFF00D9A5), textPrimary, () {
                  Navigator.pop(context);
                  _confirmDeal();
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showPriceOfferDialog() {
    final priceController = TextEditingController();
    final cardColor = AppTheme.getCardColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tawar Harga', style: TextStyle(color: AppTheme.getTextPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Masukkan nominal',
                hintStyle: TextStyle(color: textSecondary),
                prefixText: 'Rp ',
                prefixStyle: TextStyle(color: AppTheme.getTextPrimary(context)),
                filled: true,
                fillColor: AppTheme.getBackgroundColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Text('atau', style: TextStyle(color: textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _addMessage('Aku mau bantu seikhlasnya aja ya', MessageType.offer);
              },
              child: const Text('Seikhlasnya'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.isNotEmpty) {
                Navigator.pop(context);
                _addMessage('Aku tawar Rp ${priceController.text} ya, gimana?', MessageType.offer);
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _sendLocationMessage() {
    _addMessage('Lokasi saya: Kemang, Jakarta Selatan', MessageType.location);
  }

  void _confirmDeal() {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.handshake, size: 40, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 16),
            Text('Konfirmasi Deal?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text('Kamu dan ${widget.otherUserName} sudah sepakat?', textAlign: TextAlign.center, style: TextStyle(color: textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Belum')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addMessage('Deal! Terima kasih sudah membantu!', MessageType.system);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            child: const Text('Ya, Deal!'),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _addMessage(_messageController.text.trim(), MessageType.text);
    _messageController.clear();
  }

  void _addMessage(String text, MessageType type) {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId,
        senderName: 'Kamu',
        message: text,
        timestamp: DateTime.now(),
        type: type,
      ));
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
