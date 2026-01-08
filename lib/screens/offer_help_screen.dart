import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/dummy_data.dart';
import '../widgets/help_card.dart';
import '../models/help_request.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import 'request_detail_screen.dart';

class OfferHelpScreen extends StatefulWidget {
  const OfferHelpScreen({super.key});

  @override
  State<OfferHelpScreen> createState() => _OfferHelpScreenState();
}

class _OfferHelpScreenState extends State<OfferHelpScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Terdekat', 'Terbaru', 'Gratis', 'Seikhlasnya'];
  HelpCategory? _selectedCategory;
  final _locationService = LocationService();
  final _firestoreService = FirestoreService();
  bool _isLoadingLocation = false;

  List<HelpRequest> _filterRequests(List<HelpRequest> requests) {
    var filtered = requests.where((r) => r.status == HelpStatus.open).toList();
    
    if (_selectedCategory != null) {
      filtered = filtered.where((r) => r.category == _selectedCategory).toList();
    }
    
    switch (_selectedFilter) {
      case 'Gratis':
        filtered = filtered.where((r) => r.priceType == PriceType.free).toList();
        break;
      case 'Seikhlasnya':
        filtered = filtered.where((r) => r.priceType == PriceType.voluntary).toList();
        break;
      case 'Terbaru':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Terdekat':
        _sortByDistance(filtered);
        break;
    }
    
    return filtered;
  }

  void _sortByDistance(List<HelpRequest> requests) {
    final currentPos = _locationService.currentPosition;
    if (currentPos != null) {
      requests.sort((a, b) {
        if (a.latitude == null || a.longitude == null) return 1;
        if (b.latitude == null || b.longitude == null) return -1;
        
        final distA = _locationService.calculateDistance(
          currentPos.latitude, currentPos.longitude, a.latitude!, a.longitude!
        );
        final distB = _locationService.calculateDistance(
          currentPos.latitude, currentPos.longitude, b.latitude!, b.longitude!
        );
        return distA.compareTo(distB);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardColor = AppTheme.getCardColor(context);
    
    return SafeArea(
      child: StreamBuilder<List<HelpRequest>>(
        stream: _firestoreService.getOpenRequests(),
        builder: (context, snapshot) {
          final allRequests = snapshot.data ?? [];
          final filteredRequests = _filterRequests(allRequests);
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(textPrimary, textSecondary),
                    const SizedBox(height: 20),
                    _buildMotivationCard(filteredRequests.length),
                    const SizedBox(height: 20),
                    _buildCategoryFilter(cardColor, textPrimary),
                    const SizedBox(height: 16),
                    _buildFilterChips(cardColor, textSecondary),
                  ],
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting && allRequests.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredRequests.isEmpty
                        ? _buildEmptyState(textPrimary, textSecondary)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) {
                              final request = filteredRequests[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildEnhancedHelpCard(request, cardColor, textPrimary, textSecondary),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Nulong ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.accentColor, Color(0xFF00F5C4)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Bantu Sesama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Lihat siapa yang butuh bantuan di sekitarmu', style: TextStyle(fontSize: 14, color: textSecondary)),
      ],
    );
  }

  Widget _buildMotivationCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentColor, Color(0xFF00F5C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.accentColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '"Sebaik-baik manusia adalah yang paling bermanfaat"',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.track_changes, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('$count orang butuh bantuanmu', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, size: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(Color cardColor, Color textPrimary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: DummyData.categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Semua'),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
                backgroundColor: cardColor,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: _selectedCategory == null ? Colors.white : textPrimary,
                  fontWeight: _selectedCategory == null ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: _selectedCategory == null ? AppTheme.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
                ),
                showCheckmark: false,
              ),
            );
          }
          
          final category = DummyData.categories[index - 1];
          final cat = category['category'] as HelpCategory;
          final isSelected = _selectedCategory == cat;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(category['icon'] as IconData, size: 16, color: isSelected ? Colors.white : Color(category['color'])),
              label: Text(category['name']),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = isSelected ? null : cat),
              backgroundColor: cardColor,
              selectedColor: Color(category['color']),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Color(category['color']) : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(Color cardColor, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: filter == 'Terdekat' && isSelected
                  ? (_isLoadingLocation 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                      : const Icon(Icons.near_me, size: 14, color: AppTheme.primaryColor))
                  : null,
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) async {
                if (filter == 'Terdekat' && selected) {
                  setState(() => _isLoadingLocation = true);
                  await _locationService.getCurrentLocation();
                  setState(() => _isLoadingLocation = false);
                }
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: cardColor,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedHelpCard(HelpRequest request, Color cardColor, Color textPrimary, Color textSecondary) {
    final currentPos = _locationService.currentPosition;
    String? distanceText;
    
    if (currentPos != null && request.latitude != null && request.longitude != null) {
      final distance = _locationService.calculateDistance(
        currentPos.latitude, currentPos.longitude, request.latitude!, request.longitude!
      );
      distanceText = _locationService.formatDistance(distance);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToDetail(request),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(request.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(request.categoryIcon, size: 24, color: _getCategoryColor(request.category)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(request.userAvatar, size: 18, color: AppTheme.primaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(request.userName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(request.timeAgo, style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(request.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(request.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 8),
                Text(request.description, style: TextStyle(fontSize: 14, color: textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                _buildPriceInfo(request, textSecondary),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (request.location != null) ...[
                      Icon(Icons.location_on, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(request.location!, style: TextStyle(fontSize: 12, color: textSecondary), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    if (distanceText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me, size: 12, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(distanceText, style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToDetail(request),
                      icon: const Icon(Icons.handshake, size: 16),
                      label: const Text('Nulong'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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

  Widget _buildPriceInfo(HelpRequest request, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getPriceColor(request.priceType).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getPriceColor(request.priceType).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriceIcon(request.priceType), size: 16, color: _getPriceColor(request.priceType)),
          const SizedBox(width: 6),
          Text(request.priceDisplay, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _getPriceColor(request.priceType))),
          const SizedBox(width: 12),
          Container(width: 1, height: 16, color: _getPriceColor(request.priceType).withValues(alpha: 0.3)),
          const SizedBox(width: 12),
          Icon(Icons.payments_outlined, size: 14, color: textSecondary),
          const SizedBox(width: 4),
          Text(request.paymentMethodsDisplay, style: TextStyle(fontSize: 12, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(HelpStatus status) {
    Color color;
    String text;
    switch (status) {
      case HelpStatus.open: color = AppTheme.accentColor; text = 'Butuh Bantuan'; break;
      case HelpStatus.negotiating: color = const Color(0xFFFF9F43); text = 'Negosiasi'; break;
      case HelpStatus.inProgress: color = AppTheme.primaryColor; text = 'Sedang Dibantu'; break;
      case HelpStatus.completed: color = Colors.grey; text = 'Selesai'; break;
      case HelpStatus.cancelled: color = AppTheme.secondaryColor; text = 'Dibatalkan'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 48, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text('Tidak ada permintaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 8),
          Text('Coba filter lain atau refresh halaman', style: TextStyle(fontSize: 14, color: textSecondary)),
        ],
      ),
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

  Color _getPriceColor(PriceType type) {
    switch (type) {
      case PriceType.free: return AppTheme.accentColor;
      case PriceType.voluntary: return AppTheme.primaryColor;
      case PriceType.fixed: return const Color(0xFFFF9F43);
      case PriceType.negotiable: return const Color(0xFF54A0FF);
    }
  }

  IconData _getPriceIcon(PriceType type) {
    switch (type) {
      case PriceType.free: return Icons.favorite;
      case PriceType.voluntary: return Icons.volunteer_activism;
      case PriceType.fixed: return Icons.sell;
      case PriceType.negotiable: return Icons.handshake;
    }
  }

  void _navigateToDetail(HelpRequest request) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RequestDetailScreen(request: request)));
  }
}
