import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/help_request.dart';
import '../services/firestore_service.dart';
import 'help_progress_screen.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          dividerColor: AppTheme.getBorderColor(context),
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Permintaan'),
            Tab(text: 'Bantuan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveList(context),
          _buildRequestsList(context),
          _buildHelpsList(context),
        ],
      ),
    );
  }

  Widget _buildActiveList(BuildContext context) {
    return StreamBuilder<List<HelpRequest>>(
      stream: _firestoreService.getMyActiveRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final activeRequests = snapshot.data ?? [];
        
        if (activeRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: AppTheme.getTextSecondary(context)),
                const SizedBox(height: 16),
                Text('Tidak ada bantuan aktif', style: TextStyle(color: AppTheme.getTextSecondary(context))),
                const SizedBox(height: 8),
                Text('Bantuan yang sedang berjalan akan muncul di sini', 
                  style: TextStyle(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeRequests.length,
          itemBuilder: (context, index) {
            final request = activeRequests[index];
            return _buildActiveCard(context, request);
          },
        );
      },
    );
  }

  Widget _buildActiveCard(BuildContext context, HelpRequest request) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final color = _getCategoryColor(request.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HelpProgressScreen(requestId: request.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(request.categoryIcon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.location ?? 'Online',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text('Lihat Progress', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text(request.timeAgo, style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context) {
    return StreamBuilder<List<HelpRequest>>(
      stream: _firestoreService.getMyRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final myRequests = snapshot.data ?? [];
        
        if (myRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppTheme.getTextSecondary(context)),
                const SizedBox(height: 16),
                Text('Belum ada permintaan', style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myRequests.length,
          itemBuilder: (context, index) {
            final request = myRequests[index];
            return _buildActivityCard(
              context,
              request: request,
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
      },
    );
  }

  Widget _buildHelpsList(BuildContext context) {
    return StreamBuilder<List<HelpRequest>>(
      stream: _firestoreService.getMyHelping(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final myHelps = snapshot.data ?? [];
        
        if (myHelps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volunteer_activism_outlined, size: 64, color: AppTheme.getTextSecondary(context)),
                const SizedBox(height: 16),
                Text('Belum ada bantuan', style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myHelps.length,
          itemBuilder: (context, index) {
            final request = myHelps[index];
            return _buildActivityCard(
              context,
              request: request,
              icon: request.categoryIcon,
              color: _getCategoryColor(request.category),
              title: request.title,
              subtitle: request.location ?? 'Online',
              status: request.status,
              date: request.timeAgo,
              isRequest: false,
            );
          },
        );
      },
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required HelpRequest request,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = status == HelpStatus.inProgress || status == HelpStatus.onTheWay || 
                     status == HelpStatus.arrived || status == HelpStatus.working;
    
    return GestureDetector(
      onTap: isActive ? () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HelpProgressScreen(requestId: request.id)),
      ) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.1 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
      ),
    );
  }

  Widget _buildStatusChip(HelpStatus status) {
    Color color;
    String text;
    switch (status) {
      case HelpStatus.open: color = AppTheme.accentColor; text = 'Menunggu';
      case HelpStatus.negotiating: color = const Color(0xFFFF9F43); text = 'Nego';
      case HelpStatus.inProgress: color = AppTheme.primaryColor; text = 'Diterima';
      case HelpStatus.onTheWay: color = const Color(0xFF54A0FF); text = 'Perjalanan';
      case HelpStatus.arrived: color = const Color(0xFF9B59B6); text = 'Sampai';
      case HelpStatus.working: color = const Color(0xFFFF9F43); text = 'Dikerjakan';
      case HelpStatus.completed: color = Colors.grey; text = 'Selesai';
      case HelpStatus.cancelled: color = AppTheme.secondaryColor; text = 'Batal';
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
