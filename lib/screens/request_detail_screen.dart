import 'package:flutter/material.dart';
import '../models/help_request.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/pricing_service.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final HelpRequest request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _locationService = LocationService();
  final _pricingService = PricingService();
  final _firestoreService = FirestoreService();
  String? _distanceText;
  double? _distanceKm;
  bool _isLoadingDistance = false;
  PriceEstimate? _priceEstimate;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    if (widget.request.latitude == null || widget.request.longitude == null) return;
    
    setState(() => _isLoadingDistance = true);
    final position = await _locationService.getCurrentLocation();
    
    if (position != null && mounted) {
      final distance = _locationService.calculateDistance(
        position.latitude, position.longitude,
        widget.request.latitude!, widget.request.longitude!
      );
      
      // Calculate price estimate based on distance
      final estimate = _pricingService.calculatePrice(
        distanceKm: distance,
        category: widget.request.category,
      );
      
      setState(() {
        _distanceKm = distance;
        _distanceText = _locationService.formatDistance(distance);
        _priceEstimate = estimate;
        _isLoadingDistance = false;
      });
    } else {
      setState(() => _isLoadingDistance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildRequestInfo(context)),
          SliverToBoxAdapter(child: _buildPriceSection(context)),
          if (_priceEstimate != null && widget.request.location != null)
            SliverToBoxAdapter(child: _buildEstimatedPriceSection(context)),
          if (widget.request.location != null) SliverToBoxAdapter(child: _buildLocationSection(context)),
          SliverToBoxAdapter(child: _buildOffersSection(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _getCategoryColor(),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: () => _showShareSheet(),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.more_vert, color: Colors.white),
          ),
          onPressed: () => _showOptionsSheet(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_getCategoryColor(), _getCategoryColor().withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(widget.request.categoryIcon, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.request.categoryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestInfo(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Icon(widget.request.userAvatar, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.request.userName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textPrimary)),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(widget.request.timeAgo, style: TextStyle(color: textSecondary, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.request.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          Text(widget.request.description, style: TextStyle(fontSize: 15, color: textSecondary, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getPriceColor().withValues(alpha: 0.15), _getPriceColor().withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getPriceColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _getPriceColor().withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(_getPriceIcon(), color: _getPriceColor(), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ongkos Bantuan', style: TextStyle(color: textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text(widget.request.priceDisplay, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getPriceColor())),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
            child: Row(
              children: [
                Icon(Icons.payments_outlined, size: 18, color: textSecondary),
                const SizedBox(width: 6),
                Text(widget.request.paymentMethodsDisplay, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text('Lokasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
              const Spacer(),
              if (_isLoadingDistance)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              else if (_distanceText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me, size: 12, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(_distanceText!, style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Map placeholder
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withValues(alpha: 0.08), AppTheme.accentColor.withValues(alpha: 0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.place, size: 20, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.request.location!,
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildLocationButton(
                  context,
                  Icons.map_outlined,
                  'Lihat Peta',
                  () => _openInMaps(),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLocationButton(
                  context,
                  Icons.directions,
                  'Navigasi',
                  () => _openNavigation(),
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isPrimary = false}) {
    return Material(
      color: isPrimary ? AppTheme.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isPrimary ? null : Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isPrimary ? Colors.white : AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isPrimary ? Colors.white : AppTheme.primaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimatedPriceSection(BuildContext context) {
    if (_priceEstimate == null || _priceEstimate!.isFreeCategory) return const SizedBox.shrink();
    
    final cardColor = AppTheme.getCardColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF54A0FF).withValues(alpha: 0.12), const Color(0xFF54A0FF).withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF54A0FF).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF54A0FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF54A0FF), size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Estimasi Ongkos',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF54A0FF)),
                ),
              ),
              if (_distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me, size: 12, color: Color(0xFF54A0FF)),
                      const SizedBox(width: 4),
                      Text(
                        '${_distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF54A0FF)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Price display
          Text(
            _priceEstimate!.displayRange,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF54A0FF)),
          ),
          const SizedBox(height: 4),
          Text(
            _priceEstimate!.message,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 12),
          // Info note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Harga lebih murah dari ojol karena ini tolong-menolong sesama',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Store offers stream for bottom bar to check
  List<Map<String, dynamic>> _currentOffers = [];
  
  Widget _buildOffersSection(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    final currentUserId = _firestoreService.currentUserId;
    final isOwner = widget.request.userId == currentUserId;
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getOffersForRequest(widget.request.id),
      builder: (context, snapshot) {
        final offers = snapshot.data ?? [];
        _currentOffers = offers; // Store for bottom bar
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt_outlined, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Penawaran (${offers.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (offers.isEmpty)
                _buildEmptyOffers(context)
              else
                ...offers.map((offer) => _buildOfferCardFromMap(context, offer, isOwner, currentUserId)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfferCardFromMap(BuildContext context, Map<String, dynamic> offer, bool isOwner, String? currentUserId) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final helperName = offer['helperName'] ?? 'User';
    final helperId = offer['helperId'];
    final message = offer['message'];
    final offeredPrice = offer['offeredPrice'];
    final priceDisplay = offeredPrice != null ? 'Rp ${offeredPrice.toString()}' : 'Seikhlasnya';
    final isMyOffer = helperId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMyOffer ? AppTheme.primaryColor.withValues(alpha: 0.05) : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMyOffer ? AppTheme.primaryColor.withValues(alpha: 0.3) : (isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isMyOffer ? 'Kamu' : helperName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                        if (isMyOffer) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Penawaranmu', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    Text('Baru saja', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(priceDisplay, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accentColor, fontSize: 13)),
              ),
            ],
          ),
          if (message != null && message.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message, style: TextStyle(color: textSecondary, height: 1.4, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Show different buttons based on role
          if (isOwner) ...[
            // Owner can accept or chat
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChatWithHelper(offer),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptOfferFromMap(offer),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Terima'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
            ),
          ] else if (isMyOffer) ...[
            // Helper can cancel their own offer
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelOffer(offer),
                icon: Icon(Icons.close, size: 18, color: AppTheme.secondaryColor),
                label: Text('Batalkan Penawaran', style: TextStyle(color: AppTheme.secondaryColor)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: AppTheme.secondaryColor.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ] else ...[
            // Other users just see info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text('Menunggu respon', style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _acceptOfferFromMap(Map<String, dynamic> offer) async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.handshake, size: 40, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 16),
            Text('Terima Penawaran?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 8),
            Text('${offer['helperName']} akan membantu kamu', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextSecondary(context))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    final success = await _firestoreService.acceptOffer(
      offer['id'],
      widget.request.id,
      offer['helperId'],
    );
    
    if (mounted) {
      if (success) {
        // Show success dialog with chat option
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.check_circle, size: 48, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 16),
                Text('Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 8),
                Text('${offer['helperName']} akan membantu kamu.\nKoordinasikan lewat chat!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextSecondary(context))),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(this.context); // Go back to home
                },
                child: const Text('Kembali'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _openChatWithHelper(offer); // Open chat
                },
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Chat Sekarang'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Gagal menerima penawaran'), backgroundColor: AppTheme.secondaryColor, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _openChatWithHelper(Map<String, dynamic> offer) {
    final helperName = offer['helperName'] ?? 'User';
    final helperId = offer['helperId'] ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          request: widget.request,
          otherUserId: helperId,
          otherUserName: helperName,
          otherUserAvatar: Icons.person,
        ),
      ),
    );
  }

  void _cancelOffer(Map<String, dynamic> offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan Penawaran?'),
        content: const Text('Penawaran kamu akan dihapus dari permintaan ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await _firestoreService.deleteOffer(offer['id']);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Penawaran dibatalkan'), backgroundColor: AppTheme.accentColor, behavior: SnackBarBehavior.floating),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Gagal membatalkan penawaran'), backgroundColor: AppTheme.secondaryColor, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Widget _buildEmptyOffers(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.hourglass_empty, size: 32, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          Text('Belum ada penawaran', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 4),
          Text('Tunggu penolong menawarkan bantuan', style: TextStyle(fontSize: 13, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, HelpOffer offer) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Icon(offer.helperAvatar, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.helperName, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                    Text(_timeAgo(offer.createdAt), style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getOfferPriceColor(offer).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(offer.priceDisplay, style: TextStyle(fontWeight: FontWeight.w600, color: _getOfferPriceColor(offer), fontSize: 13)),
              ),
            ],
          ),
          if (offer.message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(offer.message!, style: TextStyle(color: textSecondary, height: 1.4, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(offer),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptOffer(offer),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Terima'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final currentUserId = _firestoreService.currentUserId;
    final isOwner = widget.request.userId == currentUserId;
    
    // Check if current user already has an offer
    final hasMyOffer = _currentOffers.any((offer) => offer['helperId'] == currentUserId);
    
    // Don't show offer button if user is the owner
    if (isOwner) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Ini permintaan kamu', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }
    
    // If user already offered, show different message
    if (hasMyOffer) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 8),
                Text('Kamu sudah menawarkan bantuan', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => _showOfferDialog(),
          icon: const Icon(Icons.handshake),
          label: const Text('Tawarkan Bantuan (Nulong)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  void _openInMaps() async {
    if (widget.request.latitude != null && widget.request.longitude != null) {
      final success = await _locationService.openInMaps(widget.request.latitude!, widget.request.longitude!);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Tidak dapat membuka Maps'), backgroundColor: AppTheme.secondaryColor, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _openNavigation() async {
    if (widget.request.latitude != null && widget.request.longitude != null) {
      final success = await _locationService.openNavigation(widget.request.latitude!, widget.request.longitude!);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Tidak dapat membuka navigasi'), backgroundColor: AppTheme.secondaryColor, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Bagikan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.copy, 'Salin Link', () { Navigator.pop(context); _showSnackbar('Link disalin!'); }),
                _buildShareOption(Icons.chat, 'WhatsApp', () { Navigator.pop(context); }),
                _buildShareOption(Icons.telegram, 'Telegram', () { Navigator.pop(context); }),
                _buildShareOption(Icons.more_horiz, 'Lainnya', () { Navigator.pop(context); }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.bookmark_outline), title: const Text('Simpan'), onTap: () { Navigator.pop(context); _showSnackbar('Tersimpan!'); }),
            ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Laporkan'), onTap: () { Navigator.pop(context); _showReportDialog(); }),
            ListTile(leading: Icon(Icons.block, color: AppTheme.secondaryColor), title: Text('Blokir Pengguna', style: TextStyle(color: AppTheme.secondaryColor)), onTap: () { Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Laporkan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportOption('Spam atau penipuan'),
            _buildReportOption('Konten tidak pantas'),
            _buildReportOption('Informasi palsu'),
            _buildReportOption('Lainnya'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String text) {
    return ListTile(
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        _showSnackbar('Laporan terkirim. Terima kasih!');
      },
    );
  }

  void _showOfferDialog() {
    PriceType selectedType = PriceType.voluntary;
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    PaymentMethod selectedPayment = PaymentMethod.cash;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: AppTheme.getCardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Nulong ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('Tawarkan Bantuan', style: TextStyle(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Tentukan ongkos yang kamu mau', style: TextStyle(color: AppTheme.getTextSecondary(context))),
                const SizedBox(height: 20),
                Text('Tipe Ongkos', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildOfferTypeChip(PriceType.free, 'Gratis', selectedType, (t) => setModalState(() => selectedType = t)),
                    _buildOfferTypeChip(PriceType.voluntary, 'Seikhlasnya', selectedType, (t) => setModalState(() => selectedType = t)),
                    _buildOfferTypeChip(PriceType.fixed, 'Tentukan', selectedType, (t) => setModalState(() => selectedType = t)),
                  ],
                ),
                if (selectedType == PriceType.fixed) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Masukkan nominal',
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: AppTheme.getBackgroundColor(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildPaymentOption(PaymentMethod.cash, 'Cash', selectedPayment, (p) => setModalState(() => selectedPayment = p))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPaymentOption(PaymentMethod.transfer, 'Transfer', selectedPayment, (p) => setModalState(() => selectedPayment = p))),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Pesan (Opsional)', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  style: TextStyle(color: AppTheme.getTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan untuk peminta bantuan...',
                    filled: true,
                    fillColor: AppTheme.getBackgroundColor(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      setModalState(() => isSubmitting = true);
                      
                      int? offeredPrice;
                      if (selectedType == PriceType.fixed && priceController.text.isNotEmpty) {
                        offeredPrice = int.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
                      }
                      
                      final offerId = await _firestoreService.createOffer(
                        requestId: widget.request.id,
                        message: messageController.text.isNotEmpty ? messageController.text : 'Saya siap membantu!',
                        offeredPrice: offeredPrice,
                      );
                      
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      
                      if (offerId != null) {
                        _showSnackbar('Penawaran terkirim!');
                      } else {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: const Text('Gagal mengirim penawaran. Coba lagi.'),
                            backgroundColor: AppTheme.secondaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Kirim Penawaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferTypeChip(PriceType type, String label, PriceType selected, Function(PriceType) onTap) {
    final isSelected = type == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade100), 
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.getTextPrimary(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod method, String label, PaymentMethod selected, Function(PaymentMethod) onTap) {
    final isSelected = method == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onTap(method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
        ),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? AppTheme.primaryColor : AppTheme.getTextPrimary(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
      ),
    );
  }

  void _openChat(HelpOffer offer) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(request: widget.request, otherUserId: offer.helperId, otherUserName: offer.helperName, otherUserAvatar: offer.helperAvatar)));
  }

  void _acceptOffer(HelpOffer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.handshake, size: 40, color: AppTheme.accentColor)),
            const SizedBox(height: 16),
            const Text('Terima Penawaran?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${offer.helperName} akan membantu kamu', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: _getOfferPriceColor(offer).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(offer.priceDisplay, style: TextStyle(fontWeight: FontWeight.bold, color: _getOfferPriceColor(offer), fontSize: 18)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); _showSnackbar('${offer.helperName} akan membantu!'); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor), child: const Text('Terima'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    switch (widget.request.status) {
      case HelpStatus.open: color = AppTheme.accentColor; text = 'Butuh Bantuan'; break;
      case HelpStatus.negotiating: color = const Color(0xFFFF9F43); text = 'Negosiasi'; break;
      case HelpStatus.inProgress: color = AppTheme.primaryColor; text = 'Sedang Dibantu'; break;
      case HelpStatus.completed: color = Colors.grey; text = 'Selesai'; break;
      case HelpStatus.cancelled: color = AppTheme.secondaryColor; text = 'Dibatalkan'; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)));
  }

  Color _getCategoryColor() {
    switch (widget.request.category) {
      case HelpCategory.emergency: return AppTheme.secondaryColor;
      case HelpCategory.coffee: return const Color(0xFF8B4513);
      case HelpCategory.shopping: return const Color(0xFFFF9F43);
      case HelpCategory.gaming: return const Color(0xFF9B59B6);
      case HelpCategory.hangout: return const Color(0xFF00D9A5);
      case HelpCategory.study: return const Color(0xFF54A0FF);
      default: return AppTheme.primaryColor;
    }
  }

  Color _getPriceColor() {
    switch (widget.request.priceType) {
      case PriceType.free: return AppTheme.accentColor;
      case PriceType.voluntary: return AppTheme.primaryColor;
      case PriceType.fixed: return const Color(0xFFFF9F43);
      case PriceType.negotiable: return const Color(0xFF54A0FF);
    }
  }

  IconData _getPriceIcon() {
    switch (widget.request.priceType) {
      case PriceType.free: return Icons.favorite;
      case PriceType.voluntary: return Icons.volunteer_activism;
      case PriceType.fixed: return Icons.sell;
      case PriceType.negotiable: return Icons.handshake;
    }
  }

  Color _getOfferPriceColor(HelpOffer offer) {
    switch (offer.offerType) {
      case PriceType.free: return AppTheme.accentColor;
      case PriceType.voluntary: return AppTheme.primaryColor;
      default: return const Color(0xFFFF9F43);
    }
  }
}
