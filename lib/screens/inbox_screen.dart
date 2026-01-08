import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/help_request.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inbox kosong karena belum ada chat real
    // TODO: Integrate with Firestore chat collection
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Pesan', style: TextStyle(color: AppTheme.getTextPrimary(context))),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Belum Ada Pesan',
        subtitle: 'Mulai chat dengan orang yang mau kamu bantu atau yang mau bantu kamu',
      ),
    );
  }
}
