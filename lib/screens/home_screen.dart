import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/dummy_data.dart';
import '../widgets/help_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state.dart';
import '../models/help_request.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import 'request_detail_screen.dart';
import 'notifications_screen.dart';
import 'help_progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategoryIndex = -1;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _appState = AppState();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  List<HelpRequest> _filterRequests(List<HelpRequest> requests) {
    var filtered = requests.toList();
    
    // Filter by category
    if (selectedCategoryIndex != -1) {
      final selectedCategory = DummyData.categories[selectedCategoryIndex]['category'] as HelpCategory;
      filtered = filtered.where((r) => r.category == selectedCategory).toList();
    }
    
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) =>
        r.title.toLowerCase().contains(query) ||
        r.description.toLowerCase().contains(query) ||
        r.userName.toLowerCase().contains(query) ||
        r.categoryName.toLowerCase().contains(query) ||
        (r.location?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: StreamBuilder<List<HelpRequest>>(
          stream: _firestoreService.getOpenRequests(),
          builder: (context, snapshot) {
            final allRequests = snapshot.data ?? [];
            final filteredRequests = _filterRequests(allRequests);
            
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(textPrimary, textSecondary, cardColor),
                          const SizedBox(height: 24),
                          _buildSearchBar(cardColor, textSecondary),
                          const SizedBox(height: 24),
                          _buildStatsCard(),
                          const SizedBox(height: 24),
                          // Active requests section
                          _buildActiveRequestsSection(textPrimary, textSecondary, cardColor),
                          const SizedBox(height: 24),
                          _buildCategorySection(textPrimary, textSecondary),
                          const SizedBox(height: 24),
                          _buildRequestHeader(textPrimary, textSecondary, filteredRequests.length),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting && allRequests.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _buildRequestList(filteredRequests),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary, Color cardColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = _getGreeting();
    final greetingIcon = _getGreetingIcon();
    final userName = _appState.userName;
    
    return Row(
      children: [
        // Avatar - using selected avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _appState.avatarColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _appState.avatarColor.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Icon(
              _appState.avatarIcon,
              size: 26,
              color: _appState.avatarColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(greetingIcon, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    greeting,
                    style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            _appState.markNotificationsAsRead();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Badge(
              isLabelVisible: _appState.unreadNotifications > 0,
              label: Text('${_appState.unreadNotifications}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.secondaryColor,
              child: Icon(Icons.notifications_none_rounded, color: textPrimary, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 11) return Icons.wb_sunny_outlined;
    if (hour < 15) return Icons.wb_sunny;
    if (hour < 18) return Icons.wb_twilight;
    return Icons.nightlight_outlined;
  }

  Widget _buildSearchBar(Color cardColor, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasQuery = _searchQuery.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari bantuan...',
          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: Icon(Icons.close, size: 18, color: textSecondary),
                  onPressed: () { 
                    _searchController.clear(); 
                    setState(() => _searchQuery = ''); 
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return FutureBuilder<Map<String, int>>(
      future: _firestoreService.getGlobalStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'totalHelped': 0, 'totalHelpers': 0, 'activeRequests': 0};
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildStatItem('${stats['totalHelped']}', 'Terbantu', textPrimary, textSecondary)),
              Container(width: 1, height: 32, color: AppTheme.getBorderColor(context)),
              Expanded(child: _buildStatItem('${stats['totalHelpers']}', 'Penolong', textPrimary, textSecondary)),
              Container(width: 1, height: 32, color: AppTheme.getBorderColor(context)),
              Expanded(child: _buildStatItem('${stats['activeRequests']}', 'Aktif', textPrimary, textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, Color textPrimary, Color textSecondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildCategorySection(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: DummyData.categories.length,
            itemBuilder: (context, index) {
              final category = DummyData.categories[index];
              final isSelected = selectedCategoryIndex == index;
              final color = Color(category['color']);
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => selectedCategoryIndex = selectedCategoryIndex == index ? -1 : index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color : AppTheme.getCardColor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? color : AppTheme.getBorderColor(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category['icon'] as IconData, size: 14, color: isSelected ? Colors.white : color),
                        const SizedBox(width: 5),
                        Text(
                          category['name'],
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestHeader(Color textPrimary, Color textSecondary, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('Butuh Bantuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
            ),
          ],
        ),
        if (_searchQuery.isNotEmpty || selectedCategoryIndex != -1)
          GestureDetector(
            onTap: () => setState(() { _searchQuery = ''; _searchController.clear(); selectedCategoryIndex = -1; }),
            child: Text('Reset', style: TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  Widget _buildRequestList(List<HelpRequest> requests) {
    if (requests.isEmpty) {
      // Different message based on filter state
      String title;
      String subtitle;
      bool showResetButton;
      
      if (_searchQuery.isNotEmpty) {
        title = 'Tidak ada hasil';
        subtitle = 'Coba kata kunci lain atau reset filter';
        showResetButton = true;
      } else if (selectedCategoryIndex != -1) {
        title = 'Tidak ada hasil';
        subtitle = 'Belum ada permintaan di kategori ini';
        showResetButton = true;
      } else {
        title = 'Belum ada permintaan';
        subtitle = 'Jadilah yang pertama meminta bantuan!';
        showResetButton = false;
      }
      
      return SliverFillRemaining(
        child: EmptyState(
          icon: showResetButton ? Icons.search_off : Icons.inbox_outlined,
          title: title,
          subtitle: subtitle,
          buttonText: showResetButton ? 'Reset Filter' : null,
          onButtonPressed: showResetButton ? () => setState(() { _searchQuery = ''; _searchController.clear(); selectedCategoryIndex = -1; }) : null,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HelpCard(request: requests[index], onTap: () => _navigateToDetail(requests[index])),
          ),
          childCount: requests.length,
        ),
      ),
    );
  }

  void _navigateToDetail(HelpRequest request) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RequestDetailScreen(request: request)));
  }

  Widget _buildActiveRequestsSection(Color textPrimary, Color textSecondary, Color cardColor) {
    return StreamBuilder<List<HelpRequest>>(
      stream: _firestoreService.getMyActiveRequests(),
      builder: (context, snapshot) {
        final activeRequests = snapshot.data ?? [];
        
        if (activeRequests.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Bantuan Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${activeRequests.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: activeRequests.length,
                itemBuilder: (context, index) {
                  final request = activeRequests[index];
                  return _buildActiveRequestCard(request, cardColor, textPrimary, textSecondary);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveRequestCard(HelpRequest request, Color cardColor, Color textPrimary, Color textSecondary) {
    final statusColor = _getStatusColor(request.status);
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HelpProgressScreen(requestId: request.id)),
      ),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(request.categoryIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    request.title,
                    style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(request.status), size: 10, color: statusColor),
                        const SizedBox(width: 4),
                        Text(_getStatusText(request.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress: return AppTheme.primaryColor;
      case HelpStatus.onTheWay: return const Color(0xFF54A0FF);
      case HelpStatus.arrived: return const Color(0xFF9B59B6);
      case HelpStatus.working: return const Color(0xFFFF9F43);
      default: return AppTheme.accentColor;
    }
  }

  IconData _getStatusIcon(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress: return Icons.handshake;
      case HelpStatus.onTheWay: return Icons.directions_run;
      case HelpStatus.arrived: return Icons.place;
      case HelpStatus.working: return Icons.build;
      default: return Icons.hourglass_empty;
    }
  }

  String _getStatusText(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress: return 'Diterima';
      case HelpStatus.onTheWay: return 'Perjalanan';
      case HelpStatus.arrived: return 'Sampai';
      case HelpStatus.working: return 'Dikerjakan';
      default: return 'Aktif';
    }
  }
}
