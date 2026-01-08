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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, Sahabat!', style: TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Ayo ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF8B85FF)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('TULONGEN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Icon(Icons.notifications_outlined, color: textPrimary),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.secondaryColor, shape: BoxShape.circle)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(Color cardColor, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _searchQuery.isNotEmpty ? AppTheme.primaryColor.withValues(alpha: 0.3) : (isDark ? Colors.white10 : Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari bantuan, lokasi, atau nama...',
          hintStyle: TextStyle(color: textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: _searchQuery.isNotEmpty ? AppTheme.primaryColor : textSecondary, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: Icon(Icons.close_rounded, size: 18, color: textSecondary), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF8B85FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('${_appState.totalHelped + 150}', 'Terbantu', Icons.favorite)),
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25)),
          Expanded(child: _buildStatItem('${_appState.totalHelpers + 85}', 'Penolong', Icons.people)),
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25)),
          Expanded(child: _buildStatItem('${_appState.activeRequests}', 'Aktif', Icons.access_time)),
        ],
      ),
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
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
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
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.search_off,
          title: 'Tidak ada hasil',
          subtitle: _searchQuery.isNotEmpty ? 'Coba kata kunci lain atau reset filter' : 'Belum ada permintaan di kategori ini',
          buttonText: 'Reset Filter',
          onButtonPressed: () => setState(() { _searchQuery = ''; _searchController.clear(); selectedCategoryIndex = -1; }),
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
