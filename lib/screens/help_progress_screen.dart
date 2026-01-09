import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/help_request.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/app_state.dart';
import 'chat_screen.dart';

class HelpProgressScreen extends StatefulWidget {
  final String requestId;
  
  const HelpProgressScreen({super.key, required this.requestId});

  @override
  State<HelpProgressScreen> createState() => _HelpProgressScreenState();
}

class _HelpProgressScreenState extends State<HelpProgressScreen> with TickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;
  final _appState = AppState();
  final _mapController = MapController();
  
  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  LatLng? _helperLocation;
  LatLng? _requestLocation;
  bool _isMapExpanded = false;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _startLocationTracking(bool isHelper) {
    if (!isHelper || _locationSubscription != null) return;
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update setiap 5 meter
      ),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _helperLocation = LatLng(position.latitude, position.longitude);
        });
        // Update helper location in Firestore
        _db.collection('requests').doc(widget.requestId).update({
          'helperLat': position.latitude,
          'helperLng': position.longitude,
          'helperLocationUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    }, onError: (e) {
      debugPrint('Location tracking error: $e');
    });
  }

  Future<void> _initHelperLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _helperLocation = LatLng(position.latitude, position.longitude);
        });
        // Save initial location
        await _db.collection('requests').doc(widget.requestId).update({
          'helperLat': position.latitude,
          'helperLng': position.longitude,
          'helperLocationUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error getting initial location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('requests').doc(widget.requestId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorState(context);
          }
          
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = HelpStatus.values.firstWhere(
            (s) => s.name == data['status'],
            orElse: () => HelpStatus.open,
          );
          
          // Update locations from Firestore with safe type casting
          if (data['latitude'] != null && data['longitude'] != null) {
            try {
              final lat = data['latitude'];
              final lng = data['longitude'];
              if (lat is num && lng is num) {
                _requestLocation = LatLng(lat.toDouble(), lng.toDouble());
              }
            } catch (e) {
              debugPrint('Error parsing request location: $e');
            }
          }
          if (data['helperLat'] != null && data['helperLng'] != null) {
            try {
              final lat = data['helperLat'];
              final lng = data['helperLng'];
              if (lat is num && lng is num) {
                _helperLocation = LatLng(lat.toDouble(), lng.toDouble());
              }
            } catch (e) {
              debugPrint('Error parsing helper location: $e');
            }
          }
          
          // Start tracking if helper and status is active
          final isHelper = data['helperId'] == _firestoreService.currentUserId;
          final isActiveStatus = status == HelpStatus.inProgress || 
                                 status == HelpStatus.onTheWay || 
                                 status == HelpStatus.arrived ||
                                 status == HelpStatus.working;
          
          if (isHelper && isActiveStatus) {
            if (_locationSubscription == null) {
              _startLocationTracking(true);
            }
            // Get initial location if not available
            if (_helperLocation == null) {
              _initHelperLocation();
            }
          }
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, data, status),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_shouldShowMap(status))
                        _buildLiveMapCard(context, data, status),
                      const SizedBox(height: 16),
                      _buildStatusCard(context, status, data),
                      const SizedBox(height: 16),
                      _buildProgressTimeline(context, status, data),
                      const SizedBox(height: 16),
                      _buildActionButtons(context, status, data),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowMap(HelpStatus status) {
    return status == HelpStatus.inProgress ||
           status == HelpStatus.onTheWay || 
           status == HelpStatus.arrived || 
           status == HelpStatus.working;
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Permintaan tidak ditemukan', style: TextStyle(color: AppTheme.getTextSecondary(context))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> data, HelpStatus status) {
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _getStatusColor(status),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          onPressed: () => setState(() {}),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_getStatusColor(status), _getStatusColor(status).withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getStatusIcon(status), color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      _getStatusTitle(status),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['title'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMapCard(BuildContext context, Map<String, dynamic> data, HelpStatus status) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    final hasHelperLocation = _helperLocation != null;
    final hasRequestLocation = _requestLocation != null;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isMapExpanded ? 350 : 200,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Map
            if (hasRequestLocation || hasHelperLocation)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _helperLocation ?? _requestLocation ?? const LatLng(-6.2088, 106.8456),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tolongmenolong.tolong_menolong',
                  ),
                  MarkerLayer(
                    markers: [
                      // Request location marker
                      if (hasRequestLocation)
                        Marker(
                          point: _requestLocation!,
                          width: 50,
                          height: 50,
                          child: _buildDestinationMarker(),
                        ),
                      // Helper location marker with pulse animation
                      if (hasHelperLocation)
                        Marker(
                          point: _helperLocation!,
                          width: 60,
                          height: 60,
                          child: _buildHelperMarker(),
                        ),
                    ],
                  ),
                ],
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 48, color: textSecondary.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text('Lokasi belum tersedia', style: TextStyle(color: textSecondary)),
                  ],
                ),
              ),
            
            // Top overlay - status info
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(status).withValues(alpha: 0.5 * (1 - _pulseController.value)),
                                    blurRadius: 8 * _pulseController.value,
                                    spreadRadius: 4 * _pulseController.value,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status == HelpStatus.onTheWay ? 'Live Tracking' : 'Lokasi',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Expand button
                  GestureDetector(
                    onTap: () => setState(() => _isMapExpanded = !_isMapExpanded),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                      ),
                      child: Icon(
                        _isMapExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                        size: 20,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom overlay - distance info
            if (hasHelperLocation && hasRequestLocation)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.directions_run, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jarak Penolong', style: TextStyle(fontSize: 11, color: textSecondary)),
                            Text(
                              _calculateDistance(),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getETAText(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusColor(status)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationMarker() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
          ),
          child: const Icon(Icons.place, color: Colors.white, size: 20),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildHelperMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse effect
            Container(
              width: 60 * (0.5 + 0.5 * _pulseController.value),
              height: 60 * (0.5 + 0.5 * _pulseController.value),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2 * (1 - _pulseController.value)),
                shape: BoxShape.circle,
              ),
            ),
            // Main marker
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
              ),
              child: const Icon(Icons.directions_run, color: Colors.white, size: 20),
            ),
          ],
        );
      },
    );
  }

  String _calculateDistance() {
    if (_helperLocation == null || _requestLocation == null) return '-';
    
    final distance = Geolocator.distanceBetween(
      _helperLocation!.latitude,
      _helperLocation!.longitude,
      _requestLocation!.latitude,
      _requestLocation!.longitude,
    );
    
    if (distance < 1000) {
      return '${distance.toInt()} m';
    }
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  String _getETAText() {
    if (_helperLocation == null || _requestLocation == null) return '-';
    
    final distance = Geolocator.distanceBetween(
      _helperLocation!.latitude,
      _helperLocation!.longitude,
      _requestLocation!.latitude,
      _requestLocation!.longitude,
    );
    
    // Assume average speed 30 km/h for motorcycle
    final etaMinutes = (distance / 1000) / 30 * 60;
    
    if (etaMinutes < 1) return '< 1 menit';
    if (etaMinutes < 60) return '~${etaMinutes.toInt()} menit';
    return '~${(etaMinutes / 60).toStringAsFixed(1)} jam';
  }

  Widget _buildStatusCard(BuildContext context, HelpStatus status, Map<String, dynamic> data) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    final currentUserId = _firestoreService.currentUserId;
    final isOwner = data['userId'] == currentUserId;
    final otherName = isOwner ? (data['helperName'] ?? 'Penolong') : (data['userName'] ?? 'User');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwner ? 'Penolong' : 'Peminta Bantuan',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  otherName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ],
            ),
          ),
          // Quick actions
          Row(
            children: [
              _buildQuickActionButton(
                Icons.chat_bubble_outline,
                AppTheme.primaryColor,
                () => _openChat(data),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                Icons.phone_outlined,
                AppTheme.accentColor,
                () => _showCallDialog(data),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }


  Widget _buildProgressTimeline(BuildContext context, HelpStatus currentStatus, Map<String, dynamic> data) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    final steps = [
      _ProgressStep(HelpStatus.inProgress, 'Penawaran Diterima', Icons.handshake, 'Penolong sudah siap membantu'),
      _ProgressStep(HelpStatus.onTheWay, 'Dalam Perjalanan', Icons.directions_run, 'Penolong sedang menuju lokasi'),
      _ProgressStep(HelpStatus.arrived, 'Sudah Sampai', Icons.place, 'Penolong sudah di lokasi'),
      _ProgressStep(HelpStatus.working, 'Sedang Dikerjakan', Icons.build, 'Bantuan sedang dikerjakan'),
      _ProgressStep(HelpStatus.completed, 'Selesai', Icons.check_circle, 'Bantuan sudah selesai'),
    ];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = _isStepCompleted(currentStatus, step.status);
            final isCurrent = currentStatus == step.status;
            final isLast = index == steps.length - 1;
            
            return _buildTimelineItem(
              context,
              step: step,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLast: isLast,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required _ProgressStep step,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final color = isCompleted ? AppTheme.accentColor : (isCurrent ? AppTheme.primaryColor : textSecondary.withValues(alpha: 0.3));
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? color.withValues(alpha: 0.15) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isCurrent ? 3 : 2),
                boxShadow: isCurrent ? [
                  BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2),
                ] : null,
              ),
              child: Icon(
                isCompleted ? Icons.check : step.icon,
                size: 20,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.accentColor : textSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCompleted || isCurrent ? textPrimary : textSecondary,
                          fontSize: isCurrent ? 15 : 14,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Saat ini', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isStepCompleted(HelpStatus current, HelpStatus step) {
    final order = [HelpStatus.inProgress, HelpStatus.onTheWay, HelpStatus.arrived, HelpStatus.working, HelpStatus.completed];
    final currentIndex = order.indexOf(current);
    final stepIndex = order.indexOf(step);
    return currentIndex > stepIndex;
  }

  Widget _buildActionButtons(BuildContext context, HelpStatus status, Map<String, dynamic> data) {
    final currentUserId = _firestoreService.currentUserId;
    final isOwner = data['userId'] == currentUserId;
    final isHelper = data['helperId'] == currentUserId;
    
    if (status == HelpStatus.completed) {
      return _buildCompletedSection(context, data);
    }
    
    return Column(
      children: [
        // Progress update button (for helper only)
        if (isHelper && status != HelpStatus.completed)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateProgress(status),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getNextStatusIcon(status), size: 20),
                  const SizedBox(width: 10),
                  Text(_getNextStatusLabel(status), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        // Complete button (for owner when helper marks as working)
        if (isOwner && status == HelpStatus.working)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _completeHelp(data),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 10),
                  Text('Konfirmasi Selesai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        // Cancel button
        if (status != HelpStatus.completed && status != HelpStatus.working) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(data),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: AppTheme.secondaryColor.withValues(alpha: 0.5)),
              ),
              child: Text('Batalkan', style: TextStyle(color: AppTheme.secondaryColor)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedSection(BuildContext context, Map<String, dynamic> data) {
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor.withValues(alpha: 0.15), AppTheme.accentColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.celebration, size: 56, color: AppTheme.accentColor),
          ),
          const SizedBox(height: 20),
          Text('Bantuan Selesai! 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Terima kasih sudah saling membantu',
            style: TextStyle(color: AppTheme.getTextSecondary(context), fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Kembali'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(data),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Beri Rating'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress:
        return AppTheme.primaryColor;
      case HelpStatus.onTheWay:
        return const Color(0xFF54A0FF);
      case HelpStatus.arrived:
        return const Color(0xFF9B59B6);
      case HelpStatus.working:
        return const Color(0xFFFF9F43);
      case HelpStatus.completed:
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getStatusIcon(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress:
        return Icons.handshake;
      case HelpStatus.onTheWay:
        return Icons.directions_run;
      case HelpStatus.arrived:
        return Icons.place;
      case HelpStatus.working:
        return Icons.build;
      case HelpStatus.completed:
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusTitle(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress:
        return 'Diterima';
      case HelpStatus.onTheWay:
        return 'Dalam Perjalanan';
      case HelpStatus.arrived:
        return 'Sudah Sampai';
      case HelpStatus.working:
        return 'Sedang Dikerjakan';
      case HelpStatus.completed:
        return 'Selesai';
      default:
        return 'Progress';
    }
  }

  IconData _getNextStatusIcon(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress:
        return Icons.directions_run;
      case HelpStatus.onTheWay:
        return Icons.place;
      case HelpStatus.arrived:
        return Icons.build;
      case HelpStatus.working:
        return Icons.check_circle;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getNextStatusLabel(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress:
        return 'Mulai Perjalanan';
      case HelpStatus.onTheWay:
        return 'Sudah Sampai';
      case HelpStatus.arrived:
        return 'Mulai Kerjakan';
      case HelpStatus.working:
        return 'Selesai Dikerjakan';
      default:
        return 'Update Status';
    }
  }

  HelpStatus _getNextStatus(HelpStatus status) {
    switch (status) {
      case HelpStatus.inProgress:
        return HelpStatus.onTheWay;
      case HelpStatus.onTheWay:
        return HelpStatus.arrived;
      case HelpStatus.arrived:
        return HelpStatus.working;
      case HelpStatus.working:
        return HelpStatus.completed;
      default:
        return status;
    }
  }

  void _updateProgress(HelpStatus currentStatus) async {
    final nextStatus = _getNextStatus(currentStatus);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(nextStatus).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getNextStatusIcon(currentStatus), size: 40, color: _getStatusColor(nextStatus)),
            ),
            const SizedBox(height: 16),
            Text('Update Progress?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 8),
            Text('Update status ke "${_getNextStatusLabel(currentStatus)}"?', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextSecondary(context))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _getStatusColor(nextStatus)),
            child: const Text('Ya, Update'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _firestoreService.updateRequestStatus(widget.requestId, nextStatus);
      
      // Start location tracking when going on the way
      if (nextStatus == HelpStatus.onTheWay) {
        _startLocationTracking(true);
      }
    }
  }

  void _completeHelp(Map<String, dynamic> data) async {
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
              child: Icon(Icons.check_circle, size: 48, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 16),
            Text('Konfirmasi Selesai?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 8),
            Text('Bantuan sudah selesai dikerjakan?', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.getTextSecondary(context))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Belum')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _firestoreService.updateRequestStatus(widget.requestId, HelpStatus.completed);
      await _appState.incrementHelpReceived();
      // Update helper stats only if helperId exists and user is logged in
      if (data['helperId'] != null && _firestoreService.currentUserId != null) {
        await _firestoreService.updateUserStats(helpGiven: 1);
      }
    }
  }

  void _showCancelDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batalkan Bantuan?'),
        content: const Text('Yakin ingin membatalkan bantuan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.updateRequestStatus(widget.requestId, HelpStatus.cancelled);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur telepon akan segera hadir'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRatingDialog(Map<String, dynamic> data) {
    int rating = 5;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Beri Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text('$rating / 5', style: TextStyle(color: AppTheme.getTextSecondary(context))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nanti')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Terima kasih atas ratingnya!'),
                    backgroundColor: AppTheme.accentColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(Map<String, dynamic> data) {
    final currentUserId = _firestoreService.currentUserId;
    final isOwner = data['userId'] == currentUserId;
    final otherUserId = isOwner ? data['helperId'] : data['userId'];
    final otherUserName = isOwner ? (data['helperName'] ?? 'Penolong') : (data['userName'] ?? 'User');
    
    if (otherUserId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          request: HelpRequest(
            id: widget.requestId,
            userId: data['userId'] ?? '',
            userName: data['userName'] ?? 'User',
            userAvatar: Icons.person,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            category: HelpCategory.other,
            status: HelpStatus.inProgress,
            createdAt: DateTime.now(),
          ),
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserAvatar: Icons.person,
        ),
      ),
    );
  }
}

class _ProgressStep {
  final HelpStatus status;
  final String title;
  final IconData icon;
  final String description;
  
  _ProgressStep(this.status, this.title, this.icon, this.description);
}
