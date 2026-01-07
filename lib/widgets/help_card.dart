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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: User info + Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        request.categoryIcon,
                        size: 20,
                        color: _getCategoryColor(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  request.userAvatar,
                                  size: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  request.userName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 11, color: textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                request.timeAgo,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                              if (request.location != null) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.location_on, size: 11, color: textSecondary),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    request.location!,
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Description
                Text(
                  request.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Footer: Price + Action
                Row(
                  children: [
                    Expanded(child: _buildPriceInfo(textSecondary)),
                    if (showHelpButton) ...[
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: onHelp,
                        icon: const Icon(Icons.handshake, size: 14),
                        label: const Text('Nulong', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getPriceColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriceIcon(), size: 14, color: _getPriceColor()),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              request.priceDisplay,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getPriceColor()),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 12, color: _getPriceColor().withValues(alpha: 0.3)),
          const SizedBox(width: 8),
          Icon(
            request.acceptedPayments.contains(PaymentMethod.cash) ? Icons.payments_outlined : Icons.account_balance_outlined,
            size: 12,
            color: textSecondary,
          ),
          const SizedBox(width: 4),
          Text(request.paymentMethodsDisplay, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
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

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    switch (request.status) {
      case HelpStatus.open:
        color = AppTheme.accentColor;
        text = 'Open';
        icon = Icons.fiber_manual_record;
        break;
      case HelpStatus.negotiating:
        color = const Color(0xFFFF9F43);
        text = 'Nego';
        icon = Icons.chat_bubble_outline;
        break;
      case HelpStatus.inProgress:
        color = AppTheme.primaryColor;
        text = 'Proses';
        icon = Icons.pending;
        break;
      case HelpStatus.completed:
        color = Colors.grey;
        text = 'Selesai';
        icon = Icons.check_circle_outline;
        break;
      case HelpStatus.cancelled:
        color = AppTheme.secondaryColor;
        text = 'Batal';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
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
