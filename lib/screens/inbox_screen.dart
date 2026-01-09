import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/help_request.dart';
import '../widgets/empty_state.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardColor = AppTheme.getCardColor(context);
    final currentUserId = _firestoreService.currentUserId;
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar - Clean style
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Pesan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                  ),
                ],
              ),
            ),
            // Chat List
            Expanded(
              child: currentUserId == null
                  ? Center(child: Text('Silakan login terlebih dahulu', style: TextStyle(color: textSecondary)))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('chats')
                          .where('participants', arrayContains: currentUserId)
                          .orderBy('lastMessageTime', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasError) {
                          return _buildFallbackList(currentUserId);
                        }
                        
                        final chats = snapshot.data?.docs ?? [];
                        
                        if (chats.isEmpty) {
                          return _buildEmptyState(context, textPrimary, textSecondary);
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final chat = chats[index].data() as Map<String, dynamic>;
                            final chatId = chats[index].id;
                            return _buildChatItem(context, chat, chatId, currentUserId);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackList(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final chats = snapshot.data?.docs ?? [];
        
        // Sort client-side
        chats.sort((a, b) {
          final aTime = ((a.data() as Map)['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = ((b.data() as Map)['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
        
        final textPrimary = AppTheme.getTextPrimary(context);
        final textSecondary = AppTheme.getTextSecondary(context);
        
        if (chats.isEmpty) {
          return _buildEmptyState(context, textPrimary, textSecondary);
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            final chatId = chats[index].id;
            return _buildChatItem(context, chat, chatId, currentUserId);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Color textPrimary, Color textSecondary) {
    return const EmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Belum Ada Pesan',
      subtitle: 'Mulai chat dengan menawarkan bantuan',
      iconColor: AppTheme.primaryColor,
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat, String chatId, String currentUserId) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final participants = List<String>.from(chat['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final lastMessage = chat['lastMessage'] ?? '';
    final lastMessageTime = (chat['lastMessageTime'] as Timestamp?)?.toDate();
    final requestId = chat['requestId'] ?? '';
    final lastSenderId = chat['lastSenderId'] ?? '';
    final isUnread = lastSenderId.isNotEmpty && lastSenderId != currentUserId;
    
    return FutureBuilder<DocumentSnapshot>(
      future: _db.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        final otherUserName = userSnapshot.data?.exists == true 
            ? userSnapshot.data?.get('name') ?? 'User'
            : 'User';
        
        return FutureBuilder<DocumentSnapshot>(
          future: _db.collection('requests').doc(requestId).get(),
          builder: (context, requestSnapshot) {
            final requestTitle = requestSnapshot.data?.exists == true 
                ? requestSnapshot.data?.get('title') ?? 'Permintaan'
                : 'Permintaan';
            
            return Dismissible(
              key: Key(chatId),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) => _confirmDeleteChat(context, chatId, otherUserName),
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _openChat(context, chat, chatId, otherUserId, otherUserName, requestId),
                  onLongPress: () => _showChatOptions(context, chatId, otherUserName),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 26),
                          ),
                          if (isUnread)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cardColor, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    otherUserName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lastMessageTime != null)
                                  Text(
                                    _formatTime(lastMessageTime),
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              style: TextStyle(
                                color: isUnread ? textPrimary : textSecondary,
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                requestTitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteChat(BuildContext context, String chatId, String userName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Chat?'),
        content: Text('Semua pesan dengan $userName akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await _firestoreService.deleteChat(chatId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Chat dihapus' : 'Gagal menghapus chat'),
            backgroundColor: success ? AppTheme.accentColor : AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return success;
    }
    return false;
  }

  void _showChatOptions(BuildContext context, String chatId, String userName) {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.getTextSecondary(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Chat dengan $userName', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_outline, color: AppTheme.secondaryColor),
              ),
              title: Text('Hapus Chat', style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w500)),
              subtitle: Text('Hapus semua pesan', style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(context, chatId, userName);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, Map<String, dynamic> chat, String chatId, String otherUserId, String otherUserName, String requestId) async {
    // Get request data
    final requestDoc = await _db.collection('requests').doc(requestId).get();
    
    if (requestDoc.exists) {
      final requestData = requestDoc.data()!;
      final request = HelpRequest(
        id: requestId,
        userId: requestData['userId'] ?? '',
        userName: requestData['userName'] ?? 'User',
        userAvatar: Icons.person,
        title: requestData['title'] ?? '',
        description: requestData['description'] ?? '',
        category: HelpCategory.values.firstWhere(
          (c) => c.name == requestData['category'],
          orElse: () => HelpCategory.other,
        ),
        priceType: PriceType.values.firstWhere(
          (p) => p.name == requestData['priceType'],
          orElse: () => PriceType.voluntary,
        ),
        budget: requestData['budget']?.toDouble(),
        location: requestData['location'],
        status: HelpStatus.values.firstWhere(
          (s) => s.name == requestData['status'],
          orElse: () => HelpStatus.open,
        ),
        createdAt: (requestData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              request: request,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              otherUserAvatar: Icons.person,
            ),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    if (diff.inDays < 7) return '${diff.inDays}h';
    return '${time.day}/${time.month}';
  }
}
