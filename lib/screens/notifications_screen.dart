import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notifikasi', style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'Belum Ada Notifikasi',
        subtitle: 'Notifikasi akan muncul di sini saat ada aktivitas baru',
        iconColor: AppTheme.primaryColor,
      ),
    );
  }
}
