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
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('$greeting, ', style: TextStyle(fontSize: 14, color: textSecondary)),
                  Text('Mas! ', style: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600)),
                  Icon(_getGreetingIcon(), size: 16, color: AppTheme.accentColor),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Ayo ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF8B85FF)]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Text('TULONGEN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.notifications_outlined, color: textPrimary, size: 24),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasQuery 
              ? AppTheme.primaryColor.withValues(alpha: 0.4) 
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: hasQuery ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasQuery 
                ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), 
            blurRadius: hasQuery ? 12 : 8, 
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari bantuan, lokasi, atau nama...',
          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 14),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded, 
              color: hasQuery ? AppTheme.primaryColor : textSecondary, 
              size: 22,
            ),
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 16, color: textSecondary),
                  ),
                  onPressed: () { 
                    _searchController.clear(); 
                    setState(() => _searchQuery = ''); 
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, int>>(
      future: _firestoreService.getGlobalStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'totalHelped': 0, 'totalHelpers': 0, 'activeRequests': 0};
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFF8B85FF), Color(0xFF9D97FF)], 
              begin: Alignment.topLeft, 
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Expanded(child: _buildStatItem('${stats['totalHelped']}', 'Terbantu', Icons.favorite_rounded)),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(child: _buildStatItem('${stats['totalHelpers']}', 'Penolong', Icons.people_rounded)),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(child: _buildStatItem('${stats['activeRequests']}', 'Aktif', Icons.schedule_rounded)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCategorySection(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.swipe, size: 14, color: textSecondary),
                const SizedBox(width: 4),
                Text('Geser →', style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: DummyData.categories.length,
            itemBuilder: (context, index) {
              final category = DummyData.categories[index];
              return Padding(
                padding: EdgeInsets.only(right: index < DummyData.categories.length - 1 ? 8 : 0),
                child: CategoryChip(
                  icon: category['icon'] as IconData,
                  name: category['name'],
                  color: Color(category['color']),
                  isSelected: selectedCategoryIndex == index,
                  onTap: () => setState(() => selectedCategoryIndex = selectedCategoryIndex == index ? -1 : index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestHeader(Color textPrimary, Color textSecondary, int count) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Butuh Bantuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.secondaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                ),
              ],
            ),
            if (_searchQuery.isNotEmpty || selectedCategoryIndex != -1)
              GestureDetector(
                onTap: () => setState(() { _searchQuery = ''; _searchController.clear(); selectedCategoryIndex = -1; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.secondaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt_off_rounded, size: 12, color: AppTheme.secondaryColor),
                      const SizedBox(width: 3),
                      Text('Reset', style: TextStyle(fontSize: 11, color: AppTheme.secondaryColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (selectedCategoryIndex != -1) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Color(DummyData.categories[selectedCategoryIndex]['color']).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(DummyData.categories[selectedCategoryIndex]['color']).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(DummyData.categories[selectedCategoryIndex]['icon'] as IconData, size: 14, color: Color(DummyData.categories[selectedCategoryIndex]['color'])),
                const SizedBox(width: 6),
                Text(DummyData.categories[selectedCategoryIndex]['name'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(DummyData.categories[selectedCategoryIndex]['color']))),
              ],
            ),
          ),
        ],
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
}
