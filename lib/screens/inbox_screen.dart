import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/help_request.dart';
import '../data/dummy_data.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = _getDummyChats();
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Pesan', style: TextStyle(color: AppTheme.getTextPrimary(context))),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: chats.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Belum Ada Pesan',
              subtitle: 'Mulai chat dengan orang yang mau kamu bantu atau yang mau bantu kamu',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatItem(
                  context,
                  name: chat['name'],
                  avatar: chat['avatar'],
                  lastMessage: chat['lastMessage'],
                  time: chat['time'],
                  unread: chat['unread'],
                  request: chat['request'],
                );
              },
            ),
    );
  }

  List<Map<String, dynamic>> _getDummyChats() {
    if (DummyData.helpRequests.length < 4) return [];
    return [
      {
        'name': 'Andi Pratama',
        'avatar': Icons.person,
        'lastMessage': 'Seikhlasnya aja, kebetulan searah kok 😊',
        'time': '5 menit',
        'unread': 2,
        'request': DummyData.helpRequests[3],
      },
      {
        'name': 'Bima Sakti',
        'avatar': Icons.face_rounded,
        'lastMessage': 'Bisa antar dalam 30 menit',
        'time': '15 menit',
        'unread': 0,
        'request': DummyData.helpRequests[3],
      },
      {
        'name': 'Dewi Lestari',
        'avatar': Icons.face_rounded,
        'lastMessage': 'Terima kasih banyak ya!',
        'time': '1 jam',
        'unread': 0,
        'request': DummyData.helpRequests[0],
      },
    ];
  }

  Widget _buildChatItem(
    BuildContext context, {
    required String name,
    required IconData avatar,
    required String lastMessage,
    required String time,
    required int unread,
    required HelpRequest request,
  }) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  request: request,
                  otherUserName: name,
                  otherUserAvatar: avatar,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Icon(avatar, color: AppTheme.primaryColor, size: 28),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              color: unread > 0 ? AppTheme.primaryColor : textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              request.categoryName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: TextStyle(
                                fontSize: 13,
                                color: unread > 0 ? textPrimary : textSecondary,
                                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
