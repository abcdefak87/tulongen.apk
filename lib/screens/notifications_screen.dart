import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _notifications = [
        NotificationItem(id: '1', icon: Icons.handshake, color: AppTheme.accentColor, title: 'Penawaran Baru!', message: 'Andi Pratama menawarkan bantuan untuk permintaanmu', time: '5 menit lalu', section: 'Hari Ini', isUnread: true),
        NotificationItem(id: '2', icon: Icons.chat_bubble, color: AppTheme.primaryColor, title: 'Pesan Baru', message: 'Bima Sakti: "Bisa antar dalam 30 menit"', time: '15 menit lalu', section: 'Hari Ini', isUnread: true),
        NotificationItem(id: '3', icon: Icons.check_circle, color: AppTheme.accentColor, title: 'Bantuan Selesai', message: 'Permintaan "Titip beli kopi" telah selesai', time: '1 jam lalu', section: 'Hari Ini', isUnread: false),
        NotificationItem(id: '4', icon: Icons.star, color: const Color(0xFFFFD93D), title: 'Rating Baru', message: 'Dewi Lestari memberimu rating 5 bintang!', time: 'Kemarin', section: 'Kemarin', isUnread: false),
        NotificationItem(id: '5', icon: Icons.emoji_events, color: AppTheme.primaryColor, title: 'Achievement Unlocked!', message: 'Selamat! Kamu mendapat badge "Dermawan"', time: 'Kemarin', section: 'Kemarin', isUnread: false),
        NotificationItem(id: '6', icon: Icons.campaign, color: const Color(0xFFFF9F43), title: 'Promo Spesial', message: 'Bantu 5 orang minggu ini dan dapatkan badge eksklusif!', time: '3 hari lalu', section: 'Minggu Ini', isUnread: false),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.getBackgroundColor(context);
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notifikasi', style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          if (_notifications.any((n) => n.isUnread))
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: Icon(Icons.done_all, size: 18, color: AppTheme.primaryColor),
              label: Text('Tandai Dibaca', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: 'Belum Ada Notifikasi',
                  subtitle: 'Notifikasi akan muncul di sini saat ada aktivitas baru',
                  iconColor: AppTheme.primaryColor,
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _buildListItems().length,
                    itemBuilder: (context, index) {
                      final item = _buildListItems()[index];
                      if (item is String) {
                        return _buildSectionHeader(item, textSecondary);
                      }
                      return _buildNotificationItem(item as NotificationItem, cardColor, textPrimary, textSecondary, isDark);
                    },
                  ),
                ),
    );
  }

  List<dynamic> _buildListItems() {
    List<dynamic> items = [];
    String? currentSection;
    
    for (final notification in _notifications) {
      if (notification.section != currentSection) {
        currentSection = notification.section;
        items.add(currentSection);
      }
      items.add(notification);
    }
    
    return items;
  }

  Widget _buildSectionHeader(String title, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationItem(
          id: _notifications[i].id,
          icon: _notifications[i].icon,
          color: _notifications[i].color,
          title: _notifications[i].title,
          message: _notifications[i].message,
          time: _notifications[i].time,
          section: _notifications[i].section,
          isUnread: false,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Semua notifikasi ditandai sudah dibaca'),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification, Color cardColor, Color textPrimary, Color textSecondary, bool isDark) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifikasi dihapus'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _loadNotifications();
                });
              },
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (notification.isUnread) {
            setState(() {
              final index = _notifications.indexWhere((n) => n.id == notification.id);
              if (index != -1) {
                _notifications[index] = NotificationItem(
                  id: notification.id,
                  icon: notification.icon,
                  color: notification.color,
                  title: notification.title,
                  message: notification.message,
                  time: notification.time,
                  section: notification.section,
                  isUnread: false,
                );
              }
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isUnread ? notification.color.withValues(alpha: isDark ? 0.15 : 0.05) : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: notification.isUnread ? Border.all(color: notification.color.withValues(alpha: 0.3)) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: notification.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(notification.icon, color: notification.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.w600,
                                color: textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (notification.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: notification.color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.time,
                        style: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;
  final String section;
  final bool isUnread;

  NotificationItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
    required this.section,
    required this.isUnread,
  });
}
