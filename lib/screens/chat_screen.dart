import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/help_request.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final HelpRequest request;
  final String otherUserId;
  final String otherUserName;
  final IconData otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.request,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;
  
  /// Generate consistent chat ID from two user IDs only (not request-specific)
  /// This ensures same users always share the same chat thread
  String get _chatId {
    final ids = [_firestoreService.currentUserId ?? '', widget.otherUserId];
    ids.sort();
    return ids.join('_');
  }

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
          Expanded(child: _buildMessageList(context)),
          _buildInputArea(context),
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
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryColor.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Gagal memuat pesan', style: TextStyle(color: textSecondary)),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final messages = snapshot.data?.docs ?? [];
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Mulai percakapan', style: TextStyle(color: textSecondary)),
                const SizedBox(height: 8),
                Text('Diskusikan detail bantuan', style: TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
          );
        }
        
        // Auto scroll to bottom when new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data() as Map<String, dynamic>;
            final isMe = data['senderId'] == _firestoreService.currentUserId;
            return _buildMessageBubble(context, data, isMe, doc.id);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message, bool isMe, String messageId) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final timestamp = (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    
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
            child: GestureDetector(
              onLongPress: isMe ? () => _showDeleteMessageDialog(messageId, message['message'] ?? '') : null,
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
                    Text(message['message'] ?? '', style: TextStyle(color: isMe ? Colors.white : textPrimary, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 4),
                    Text(_formatTime(timestamp), style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteMessageDialog(String messageId, String messagePreview) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Pesan?', style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                messagePreview.length > 50 ? '${messagePreview.substring(0, 50)}...' : messagePreview,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text('Pesan akan dihapus permanen', style: TextStyle(color: textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _firestoreService.deleteMessage(_chatId, messageId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Pesan dihapus' : 'Gagal menghapus pesan'),
                    backgroundColor: success ? AppTheme.accentColor : AppTheme.secondaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use slightly different color for better contrast
    final inputBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.grey.shade100;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: AppTheme.primaryColor, size: 22),
                onPressed: () => _showQuickActions(),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.12) 
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: textPrimary, fontSize: 15),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan...',
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        icon: Icon(Icons.emoji_emotions_outlined, color: textSecondary, size: 22),
                        onPressed: () {},
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF8B85FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _sendMessage,
                padding: EdgeInsets.zero,
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
                  _sendQuickMessage('📍 Lokasi saya sudah saya share');
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
                _sendQuickMessage('💰 Aku mau bantu seikhlasnya aja ya');
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
                _sendQuickMessage('💰 Aku tawar Rp ${priceController.text} ya, gimana?');
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
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
              _sendQuickMessage('🤝 Deal! Terima kasih!');
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
    _sendToFirestore(_messageController.text.trim());
    _messageController.clear();
  }

  void _sendQuickMessage(String text) {
    _sendToFirestore(text);
  }

  Future<void> _sendToFirestore(String text) async {
    final currentUserId = _firestoreService.currentUserId;
    if (currentUserId == null) return;
    
    try {
      // Create chat document if not exists
      await _db.collection('chats').doc(_chatId).set({
        'requestId': widget.request.id,
        'participants': [currentUserId, widget.otherUserId],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Add message
      await _db.collection('chats').doc(_chatId).collection('messages').add({
        'senderId': currentUserId,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan: $e'), backgroundColor: AppTheme.secondaryColor),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
