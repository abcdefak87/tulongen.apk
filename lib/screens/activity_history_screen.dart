import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/dummy_data.dart';
import '../models/help_request.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Riwayat Aktivitas', style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: AppTheme.primaryColor,
          dividerColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          tabs: const [
            Tab(text: 'Permintaan Saya'),
            Tab(text: 'Bantuan Saya'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList(context),
          _buildHelpsList(context),
        ],
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context) {
    final myRequests = DummyData.helpRequests.take(3).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myRequests.length,
      itemBuilder: (context, index) {
        final request = myRequests[index];
        return _buildActivityCard(
          context,
          icon: request.categoryIcon,
          color: _getCategoryColor(request.category),
          title: request.title,
          subtitle: request.location ?? 'Online',
          status: request.status,
          date: request.timeAgo,
          isRequest: true,
        );
      },
    );
  }

  Widget _buildHelpsList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActivityCard(
          context,
          icon: Icons.coffee_rounded,
          color: const Color(0xFF8B4513),
          title: 'Titip beli kopi Starbucks',
          subtitle: 'Kemang, Jakarta',
          status: HelpStatus.completed,
          date: '2 hari lalu',
          isRequest: false,
        ),
        _buildActivityCard(
          context,
          icon: Icons.shopping_bag_rounded,
          color: const Color(0xFFFF9F43),
          title: 'Titip beli Mixue',
          subtitle: 'Tebet, Jakarta',
          status: HelpStatus.completed,
          date: '5 hari lalu',
          isRequest: false,
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required HelpStatus status,
    required String date,
    required bool isRequest,
  }) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusChip(status),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(HelpStatus status) {
    Color color;
    String text;
    switch (status) {
      case HelpStatus.open: color = AppTheme.accentColor; text = 'Aktif'; break;
      case HelpStatus.negotiating: color = const Color(0xFFFF9F43); text = 'Nego'; break;
      case HelpStatus.inProgress: color = AppTheme.primaryColor; text = 'Proses'; break;
      case HelpStatus.completed: color = Colors.grey; text = 'Selesai'; break;
      case HelpStatus.cancelled: color = AppTheme.secondaryColor; text = 'Batal'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _getCategoryColor(HelpCategory category) {
    switch (category) {
      case HelpCategory.emergency: return AppTheme.secondaryColor;
      case HelpCategory.coffee: return const Color(0xFF8B4513);
      case HelpCategory.shopping: return const Color(0xFFFF9F43);
      case HelpCategory.gaming: return const Color(0xFF9B59B6);
      case HelpCategory.hangout: return const Color(0xFF00D9A5);
      case HelpCategory.study: return const Color(0xFF54A0FF);
      default: return AppTheme.primaryColor;
    }
  }
}
