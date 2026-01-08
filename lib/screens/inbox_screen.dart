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
    final currentUserId = _firestoreService.currentUserId;
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Pesan', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: currentUserId == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
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
                  debugPrint('Inbox error: ${snapshot.error}');
                  // Fallback: try without orderBy (might need index)
                  return _buildFallbackList(currentUserId);
                }
                
                final chats = snapshot.data?.docs ?? [];
                
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
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.accentColor.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.chat_bubble_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inbox Kosong', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text('Mulai chat dengan menawarkan bantuan', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Belum Ada Pesan',
            subtitle: 'Mulai chat dengan orang yang mau kamu bantu atau yang mau bantu kamu',
            iconColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat, String chatId, String currentUserId) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    final participants = List<String>.from(chat['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final lastMessage = chat['lastMessage'] ?? '';
    final lastMessageTime = (chat['lastMessageTime'] as Timestamp?)?.toDate();
    final requestId = chat['requestId'] ?? '';
    
    return FutureBuilder<DocumentSnapshot>(
      future: _db.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        final otherUserName = userSnapshot.data?.get('name') ?? 'User';
        
        return FutureBuilder<DocumentSnapshot>(
          future: _db.collection('requests').doc(requestId).get(),
          builder: (context, requestSnapshot) {
            final requestTitle = requestSnapshot.data?.exists == true 
                ? requestSnapshot.data?.get('title') ?? 'Permintaan'
                : 'Permintaan';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                title: Text(otherUserName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        requestTitle,
                        style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: lastMessageTime != null
                    ? Text(_formatTime(lastMessageTime), style: TextStyle(fontSize: 11, color: textSecondary))
                    : null,
                onTap: () => _openChat(context, chat, chatId, otherUserId, otherUserName, requestId),
              ),
            );
          },
        );
      },
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
