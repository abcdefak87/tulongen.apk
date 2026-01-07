import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;
  final Widget? customIllustration;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primaryColor;
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIllustration ?? _buildDefaultIllustration(color),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIllustration(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
          ),
          child: Icon(icon, size: 56, color: color),
        ),
      ),
    );
  }
}

// Specific empty states for different scenarios
class NoRequestsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateRequest;

  const NoRequestsEmptyState({super.key, this.onCreateRequest});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inbox_rounded,
      title: 'Belum Ada Permintaan',
      subtitle: 'Jadilah yang pertama meminta bantuan atau bantu orang lain di sekitarmu!',
      buttonText: 'Buat Permintaan',
      onButtonPressed: onCreateRequest,
      iconColor: AppTheme.primaryColor,
    );
  }
}

class NoMessagesEmptyState extends StatelessWidget {
  const NoMessagesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Belum Ada Pesan',
      subtitle: 'Mulai percakapan dengan menawarkan bantuan atau meminta tolong!',
      iconColor: AppTheme.accentColor,
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  final VoidCallback? onReset;

  const SearchEmptyState({super.key, this.onReset});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'Tidak Ditemukan',
      subtitle: 'Coba kata kunci lain atau reset filter pencarian',
      buttonText: 'Reset Filter',
      onButtonPressed: onReset,
      iconColor: AppTheme.secondaryColor,
    );
  }
}
