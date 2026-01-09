import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../services/firestore_service.dart';
import '../models/help_request.dart';
import 'request_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final currentUserId = _firestoreService.currentUserId;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notifikasi', style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: currentUserId == null
          ? const EmptyState(
              icon: Icons.login_outlined,
              title: 'Belum Login',
              subtitle: 'Silakan login untuk melihat notifikasi',
              iconColor: AppTheme.primaryColor,
            )
          : _buildNotificationsList(context, currentUserId),
    );
  }

  Widget _buildNotificationsList(BuildContext context, String currentUserId) {
    // Get my requests first, then get offers for those requests
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('requests')
          .where('userId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, requestSnapshot) {
        if (requestSnapshot.hasError) {
          return Center(
            child: Text('Error: ${requestSnapshot.error}', 
              style: TextStyle(color: AppTheme.getTextSecondary(context))),
          );
        }
        
        if (requestSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final myRequests = requestSnapshot.data?.docs ?? [];
        
        if (myRequests.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'Belum Ada Notifikasi',
            subtitle: 'Buat permintaan bantuan untuk menerima penawaran',
            iconColor: AppTheme.primaryColor,
          );
        }

        final myRequestIds = myRequests.map((r) => r.id).toList();

        // Get all offers for my requests
        return StreamBuilder<QuerySnapshot>(
          stream: _db.collection('offers').snapshots(),
          builder: (context, offerSnapshot) {
            if (offerSnapshot.hasError) {
              return Center(
                child: Text('Error: ${offerSnapshot.error}',
                  style: TextStyle(color: AppTheme.getTextSecondary(context))),
              );
            }
            
            if (offerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allOffers = offerSnapshot.data?.docs ?? [];
            final myRequestIdSet = myRequestIds.toSet();
            
            // Filter offers for my requests
            final myOffers = allOffers.where((o) {
              final data = o.data() as Map<String, dynamic>?;
              if (data == null) return false;
              return myRequestIdSet.contains(data['requestId']);
            }).toList();

            // Sort by createdAt descending
            myOffers.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>?;
              final bData = b.data() as Map<String, dynamic>?;
              final aTime = (aData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
              final bTime = (bData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
              return bTime.compareTo(aTime);
            });

            if (myOffers.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Belum Ada Penawaran',
                subtitle: 'Tunggu penolong menawarkan bantuan',
                iconColor: AppTheme.primaryColor,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myOffers.length,
              itemBuilder: (context, index) {
                final offerData = myOffers[index].data() as Map<String, dynamic>?;
                if (offerData == null) return const SizedBox.shrink();
                
                final offerId = myOffers[index].id;
                final requestId = offerData['requestId'] ?? '';
                
                // Find the request for this offer
                QueryDocumentSnapshot? requestDoc;
                try {
                  requestDoc = myRequests.firstWhere((r) => r.id == requestId);
                } catch (_) {
                  requestDoc = null;
                }
                
                final requestData = (requestDoc?.data() as Map<String, dynamic>?) ?? {};
                
                return _buildOfferNotificationCard(context, offerData, offerId, requestData, requestId);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOfferNotificationCard(
    BuildContext context,
    Map<String, dynamic> offer,
    String offerId,
    Map<String, dynamic> request,
    String requestId,
  ) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final helperName = offer['helperName'] ?? 'Seseorang';
    final message = offer['message'] ?? '';
    final offeredPrice = offer['offeredPrice'];
    final status = offer['status'] ?? 'pending';
    final createdAt = (offer['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final requestTitle = request['title'] ?? 'Permintaan';

    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'accepted':
        statusColor = AppTheme.accentColor;
        statusText = 'Diterima';
        statusIcon = Icons.check_circle_outline;
      case 'rejected':
        statusColor = AppTheme.secondaryColor;
        statusText = 'Ditolak';
        statusIcon = Icons.cancel_outlined;
      default:
        statusColor = AppTheme.primaryColor;
        statusText = 'Menunggu';
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
      child: InkWell(
        onTap: () => _openRequestDetail(requestId),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.handshake_outlined, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$helperName mau bantu!',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          requestTitle,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusText, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.getBackgroundColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote, size: 14, color: textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (offeredPrice != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Rp $offeredPrice',
                        style: TextStyle(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Seikhlasnya',
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatTimeAgo(createdAt),
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRequestDetail(String requestId) async {
    final doc = await _db.collection('requests').doc(requestId).get();
    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    final request = HelpRequest(
      id: requestId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      userAvatar: Icons.person,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: HelpCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => HelpCategory.other,
      ),
      priceType: PriceType.values.firstWhere(
        (p) => p.name == data['priceType'],
        orElse: () => PriceType.voluntary,
      ),
      budget: data['budget']?.toDouble(),
      location: data['location'],
      status: HelpStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => HelpStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RequestDetailScreen(request: request)),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${time.day}/${time.month}';
  }
}
