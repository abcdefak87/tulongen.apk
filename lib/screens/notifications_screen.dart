import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../services/firestore_service.dart';
import 'help_progress_screen.dart';
import 'chat_screen.dart';
import '../models/help_request.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final currentUserId = _firestoreService.currentUserId;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notifikasi', style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(),
            child: Text('Tandai dibaca', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
          ),
        ],
      ),
      body: currentUserId == null
          ? const EmptyState(
              icon: Icons.login_outlined,
              title: 'Belum Login',
              subtitle: 'Silakan login untuk melihat notifikasi',
              iconColor: AppTheme.primaryColor,
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUserId)
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildNotificationsList(context, currentUserId);
                }

                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return _buildNotificationsList(context, currentUserId);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index].data() as Map<String, dynamic>;
                    final notifId = notifications[index].id;
                    return _buildNotificationItem(context, notif, notifId);
                  },
                );
              },
            ),
    );
  }

  /// Fallback: Build notifications from activity (offers, messages, status changes)
  Widget _buildNotificationsList(BuildContext context, String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('requests')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, requestSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('chats')
              .where('participants', arrayContains: currentUserId)
              .orderBy('lastMessageTime', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, chatSnapshot) {
            final requests = requestSnapshot.data?.docs ?? [];
            final chats = chatSnapshot.data?.docs ?? [];

            // Build notification items from real data
            final List<_NotificationData> notifItems = [];

            // Add request-based notifications (offers received)
            for (final doc in requests) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'open';
              final title = data['title'] ?? '';
              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              
              if (status == 'inProgress' || status == 'negotiating') {
                notifItems.add(_NotificationData(
                  type: 'offer',
                  title: 'Ada yang mau bantu!',
                  message: 'Permintaan "$title" mendapat respon',
                  time: updatedAt,
                  requestId: doc.id,
                  icon: Icons.handshake_outlined,
                  color: AppTheme.accentColor,
                ));
              } else if (status == 'completed') {
                notifItems.add(_NotificationData(
                  type: 'completed',
                  title: 'Bantuan Selesai',
                  message: '"$title" telah selesai',
                  time: updatedAt,
                  requestId: doc.id,
                  icon: Icons.check_circle_outline,
                  color: AppTheme.accentColor,
                ));
              }
            }

            // Add chat-based notifications
            for (final doc in chats) {
              final data = doc.data() as Map<String, dynamic>;
              final lastMessage = data['lastMessage'] ?? '';
              final lastTime = (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();
              
              if (lastMessage.isNotEmpty) {
                notifItems.add(_NotificationData(
                  type: 'message',
                  title: 'Pesan Baru',
                  message: lastMessage,
                  time: lastTime,
                  chatId: doc.id,
                  icon: Icons.chat_bubble_outline,
                  color: AppTheme.primaryColor,
                ));
              }
            }

            // Sort by time
            notifItems.sort((a, b) => b.time.compareTo(a.time));

            if (notifItems.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Belum Ada Notifikasi',
                subtitle: 'Notifikasi akan muncul saat ada aktivitas baru',
                iconColor: AppTheme.primaryColor,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifItems.length,
              itemBuilder: (context, index) {
                final item = notifItems[index];
                return _buildNotificationCard(context, item);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, _NotificationData item) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        title: Text(
          item.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.message,
              style: TextStyle(fontSize: 13, color: textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              _formatTimeAgo(item.time),
              style: TextStyle(fontSize: 11, color: textSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(context, item),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> notif, String notifId) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isRead = notif['isRead'] ?? false;
    final type = notif['type'] ?? 'general';
    final title = notif['title'] ?? 'Notifikasi';
    final message = notif['message'] ?? '';
    final createdAt = (notif['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    IconData icon;
    Color color;
    switch (type) {
      case 'offer':
        icon = Icons.handshake_outlined;
        color = AppTheme.accentColor;
      case 'message':
        icon = Icons.chat_bubble_outline;
        color = AppTheme.primaryColor;
      case 'completed':
        icon = Icons.check_circle_outline;
        color = AppTheme.accentColor;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        color = AppTheme.secondaryColor;
      default:
        icon = Icons.notifications_outlined;
        color = AppTheme.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? cardColor : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isRead ? AppTheme.getBorderColor(context) : color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              _formatTimeAgo(createdAt),
              style: TextStyle(fontSize: 11, color: textSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
        onTap: () {
          _markAsRead(notifId);
          _handleNotificationTapFromData(context, notif);
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, _NotificationData item) {
    if (item.type == 'offer' || item.type == 'completed') {
      if (item.requestId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HelpProgressScreen(requestId: item.requestId!)),
        );
      }
    }
    // For messages, could navigate to chat
  }

  void _handleNotificationTapFromData(BuildContext context, Map<String, dynamic> notif) {
    final type = notif['type'] ?? '';
    final requestId = notif['requestId'];
    
    if ((type == 'offer' || type == 'completed') && requestId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HelpProgressScreen(requestId: requestId)),
      );
    }
  }

  Future<void> _markAsRead(String notifId) async {
    try {
      await _db.collection('notifications').doc(notifId).update({'isRead': true});
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _markAllAsRead() async {
    final currentUserId = _firestoreService.currentUserId;
    if (currentUserId == null) return;

    try {
      final batch = _db.batch();
      final notifications = await _db
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Semua notifikasi ditandai dibaca'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Ignore errors
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _NotificationData {
  final String type;
  final String title;
  final String message;
  final DateTime time;
  final String? requestId;
  final String? chatId;
  final IconData icon;
  final Color color;

  _NotificationData({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.requestId,
    this.chatId,
    required this.icon,
    required this.color,
  });
}
