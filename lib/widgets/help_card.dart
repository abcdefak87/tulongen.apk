import 'package:flutter/material.dart';
import '../models/help_request.dart';
import '../theme/app_theme.dart';

class HelpCard extends StatelessWidget {
  final HelpRequest request;
  final bool showHelpButton;
  final VoidCallback? onHelp;
  final VoidCallback? onTap;

  const HelpCard({
    super.key,
    required this.request,
    this.showHelpButton = false,
    this.onHelp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final categoryColor = _getCategoryColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryColor.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getCategoryColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(request.categoryIcon, size: 20, color: _getCategoryColor()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.userName,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.timeAgo,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  request.title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Description
                Text(
                  request.description,
                  style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPriceColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getPriceIcon(), size: 14, color: _getPriceColor()),
                          const SizedBox(width: 4),
                          Text(
                            request.priceDisplay,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getPriceColor()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Location
                    if (request.location != null) ...[
                      Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          request.location!,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    // Help button
                    if (showHelpButton)
                      TextButton(
                        onPressed: onHelp,
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Nulong', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    switch (request.status) {
      case HelpStatus.open: color = AppTheme.accentColor; text = 'Open';
      case HelpStatus.negotiating: color = const Color(0xFFFF9F43); text = 'Nego';
      case HelpStatus.inProgress: color = AppTheme.primaryColor; text = 'Proses';
      case HelpStatus.onTheWay: color = const Color(0xFF54A0FF); text = 'Jalan';
      case HelpStatus.arrived: color = const Color(0xFF9B59B6); text = 'Sampai';
      case HelpStatus.working: color = const Color(0xFFFF9F43); text = 'Kerja';
      case HelpStatus.completed: color = Colors.grey; text = 'Selesai';
      case HelpStatus.cancelled: color = AppTheme.secondaryColor; text = 'Batal';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  IconData _getPriceIcon() {
    switch (request.priceType) {
      case PriceType.free: return Icons.favorite;
      case PriceType.voluntary: return Icons.volunteer_activism;
      case PriceType.fixed: return Icons.sell;
      case PriceType.negotiable: return Icons.handshake;
    }
  }

  Color _getPriceColor() {
    switch (request.priceType) {
      case PriceType.free: return AppTheme.accentColor;
      case PriceType.voluntary: return AppTheme.primaryColor;
      case PriceType.fixed: return const Color(0xFFFF9F43);
      case PriceType.negotiable: return const Color(0xFF54A0FF);
    }
  }

  Color _getCategoryColor() {
    switch (request.category) {
      case HelpCategory.emergency: return AppTheme.secondaryColor;
      case HelpCategory.daily: return AppTheme.primaryColor;
      case HelpCategory.education: return AppTheme.accentColor;
      case HelpCategory.health: return const Color(0xFFE74C3C);
      case HelpCategory.transport: return const Color(0xFF6C63FF);
      case HelpCategory.coffee: return const Color(0xFF8B4513);
      case HelpCategory.shopping: return const Color(0xFFFF9F43);
      case HelpCategory.gaming: return const Color(0xFF9B59B6);
      case HelpCategory.study: return const Color(0xFF54A0FF);
      case HelpCategory.hangout: return const Color(0xFF00D9A5);
      case HelpCategory.other: return const Color(0xFF95A5A6);
    }
  }
}
