import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/help_request.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
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
      body: Column(
        children: [
          // Quick stats
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
          // Empty state
          const Expanded(
            child: EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Belum Ada Pesan',
              subtitle: 'Mulai chat dengan orang yang mau kamu bantu atau yang mau bantu kamu',
              iconColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
