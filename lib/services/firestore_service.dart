import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/help_request.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ============ HELP REQUESTS ============

  // Create new help request
  Future<String?> createHelpRequest({
    required String title,
    required String description,
    required HelpCategory category,
    required PriceType priceType,
    double? budget,
    String? location,
    double? latitude,
    double? longitude,
    List<PaymentMethod> acceptedPayments = const [PaymentMethod.cash],
  }) async {
    if (currentUserId == null) {
      debugPrint('createHelpRequest: No user logged in');
      return null;
    }
    
    try {
      final userData = await getUserData(currentUserId!);
      final data = {
        'userId': currentUserId,
        'userName': userData?['name'] ?? 'User',
        'title': title,
        'description': description,
        'category': category.name,
        'priceType': priceType.name,
        'budget': budget,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'acceptedPayments': acceptedPayments.map((p) => p.name).toList(),
        'status': HelpStatus.open.name,
        'createdAt': FieldValue.serverTimestamp(),
      };
      debugPrint('createHelpRequest: Creating with data: $data');
      final doc = await _db.collection('requests').add(data);
      debugPrint('createHelpRequest: Created with ID: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('createHelpRequest error: $e');
      return null;
    }
  }

  // Get all open help requests (for home screen)
  // Note: This query requires a composite index in Firestore
  // If index doesn't exist, it will fall back to client-side sorting
  Stream<List<HelpRequest>> getOpenRequests() {
    return _db
        .collection('requests')
        .where('status', isEqualTo: HelpStatus.open.name)
        .snapshots()
        .handleError((error) {
          debugPrint('Error getting open requests: $error');
        })
        .map((snapshot) {
          debugPrint('Got ${snapshot.docs.length} open requests');
          final requests = snapshot.docs.map((doc) => _docToHelpRequest(doc)).toList();
          // Sort client-side to avoid needing composite index
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Get requests by category
  Stream<List<HelpRequest>> getRequestsByCategory(HelpCategory category) {
    return _db
        .collection('requests')
        .where('status', isEqualTo: HelpStatus.open.name)
        .where('category', isEqualTo: category.name)
        .snapshots()
        .handleError((error) {
          debugPrint('Error getting requests by category: $error');
        })
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) => _docToHelpRequest(doc)).toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Get my requests (yang saya buat)
  Stream<List<HelpRequest>> getMyRequests() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('requests')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .handleError((error) {
          debugPrint('Error getting my requests: $error');
        })
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) => _docToHelpRequest(doc)).toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Get requests I'm helping
  Stream<List<HelpRequest>> getMyHelping() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('requests')
        .where('helperId', isEqualTo: currentUserId)
        .snapshots()
        .handleError((error) {
          debugPrint('Error getting my helping: $error');
        })
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) => _docToHelpRequest(doc)).toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Get my active requests (in progress, on the way, arrived, working)
  Stream<List<HelpRequest>> getMyActiveRequests() {
    if (currentUserId == null) return Stream.value([]);
    
    final activeStatuses = [
      HelpStatus.inProgress.name,
      HelpStatus.onTheWay.name,
      HelpStatus.arrived.name,
      HelpStatus.working.name,
    ];
    
    return _db
        .collection('requests')
        .snapshots()
        .handleError((error) {
          debugPrint('Error getting active requests: $error');
        })
        .map((snapshot) {
          final requests = snapshot.docs
              .where((doc) {
                final data = doc.data();
                final status = data['status'] as String?;
                final userId = data['userId'] as String?;
                final helperId = data['helperId'] as String?;
                return activeStatuses.contains(status) &&
                       (userId == currentUserId || helperId == currentUserId);
              })
              .map((doc) => _docToHelpRequest(doc))
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Update request status
  Future<bool> updateRequestStatus(String requestId, HelpStatus status, {String? helperId}) async {
    try {
      final updates = <String, dynamic>{'status': status.name};
      if (helperId != null) updates['helperId'] = helperId;
      await _db.collection('requests').doc(requestId).update(updates);
      debugPrint('updateRequestStatus: $requestId -> ${status.name}');
      return true;
    } catch (e) {
      debugPrint('updateRequestStatus error: $e');
      return false;
    }
  }

  // Check if request is still open (for validation before accepting offer)
  Future<bool> isRequestOpen(String requestId) async {
    try {
      final doc = await _db.collection('requests').doc(requestId).get();
      if (!doc.exists) return false;
      final status = doc.data()?['status'] as String?;
      return status == HelpStatus.open.name;
    } catch (e) {
      debugPrint('isRequestOpen error: $e');
      return false;
    }
  }

  // Delete request
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _db.collection('requests').doc(requestId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  HelpRequest _docToHelpRequest(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return HelpRequest(
      id: doc.id,
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
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      acceptedPayments: (data['acceptedPayments'] as List<dynamic>?)
          ?.map((p) => PaymentMethod.values.firstWhere((m) => m.name == p, orElse: () => PaymentMethod.cash))
          .toList() ?? [PaymentMethod.cash],
      status: HelpStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => HelpStatus.open,
      ),
      createdAt: createdAt,
    );
  }


  // ============ USER DATA ============

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserStats({int? helpGiven, int? helpReceived}) async {
    if (currentUserId == null) return false;
    try {
      final updates = <String, dynamic>{};
      if (helpGiven != null) updates['helpGiven'] = FieldValue.increment(helpGiven);
      if (helpReceived != null) updates['helpReceived'] = FieldValue.increment(helpReceived);
      await _db.collection('users').doc(currentUserId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserPhoto(String photoUrl) async {
    if (currentUserId == null) return false;
    try {
      await _db.collection('users').doc(currentUserId).update({'photoUrl': photoUrl});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ OFFERS ============

  Future<String?> createOffer({
    required String requestId,
    required String message,
    int? offeredPrice,
  }) async {
    if (currentUserId == null) {
      debugPrint('createOffer: No user logged in');
      return null;
    }
    
    try {
      // Check if request is still open
      final isOpen = await isRequestOpen(requestId);
      if (!isOpen) {
        debugPrint('createOffer: Request is no longer open');
        return null;
      }
      
      // Check if user already has pending offer for this request
      final existingOffer = await _db
          .collection('offers')
          .where('requestId', isEqualTo: requestId)
          .where('helperId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (existingOffer.docs.isNotEmpty) {
        debugPrint('createOffer: User already has pending offer');
        return null;
      }
      
      final userData = await getUserData(currentUserId!);
      final doc = await _db.collection('offers').add({
        'requestId': requestId,
        'helperId': currentUserId,
        'helperName': userData?['name'] ?? 'User',
        'message': message,
        'offeredPrice': offeredPrice,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('createOffer: Created offer ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('createOffer error: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getOffersForRequest(String requestId) {
    return _db
        .collection('offers')
        .where('requestId', isEqualTo: requestId)
        .snapshots()
        .handleError((error) {
          debugPrint('Error getting offers: $error');
        })
        .map((snapshot) {
          final offers = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          // Sort by createdAt descending
          offers.sort((a, b) {
            final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return offers;
        });
  }

  Future<bool> deleteOffer(String offerId) async {
    try {
      await _db.collection('offers').doc(offerId).delete();
      return true;
    } catch (e) {
      debugPrint('deleteOffer error: $e');
      return false;
    }
  }

  Future<bool> acceptOffer(String offerId, String requestId, String helperId) async {
    if (currentUserId == null) {
      debugPrint('acceptOffer: No user logged in');
      return false;
    }
    
    try {
      // 1. Check if request is still open
      final isOpen = await isRequestOpen(requestId);
      if (!isOpen) {
        debugPrint('acceptOffer: Request is no longer open');
        return false;
      }
      
      // 2. Get helper name
      final helperData = await getUserData(helperId);
      final helperName = helperData?['name'] ?? 'Penolong';
      
      // 3. Use batch to update atomically
      final batch = _db.batch();
      
      // Accept this offer
      batch.update(_db.collection('offers').doc(offerId), {'status': 'accepted'});
      
      // Update request status
      batch.update(_db.collection('requests').doc(requestId), {
        'status': HelpStatus.inProgress.name,
        'helperId': helperId,
        'helperName': helperName,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      
      // 4. Reject all other pending offers for this request
      final otherOffers = await _db
          .collection('offers')
          .where('requestId', isEqualTo: requestId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      for (final doc in otherOffers.docs) {
        if (doc.id != offerId) {
          batch.update(doc.reference, {'status': 'rejected'});
        }
      }
      
      await batch.commit();
      debugPrint('acceptOffer: Successfully accepted offer $offerId');
      return true;
    } catch (e) {
      debugPrint('acceptOffer error: $e');
      return false;
    }
  }

  // ============ CHAT / MESSAGES ============

  /// Delete a single message from a chat
  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('deleteMessage error: $e');
      return false;
    }
  }

  /// Delete entire chat conversation
  Future<bool> deleteChat(String chatId) async {
    try {
      // Delete all messages first
      final messages = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      
      for (final doc in messages.docs) {
        await doc.reference.delete();
      }
      
      // Delete chat document
      await _db.collection('chats').doc(chatId).delete();
      return true;
    } catch (e) {
      debugPrint('deleteChat error: $e');
      return false;
    }
  }

  // ============ STATS ============

  Future<Map<String, int>> getGlobalStats() async {
    try {
      final requests = await _db.collection('requests').get();
      final users = await _db.collection('users').get();
      final completed = requests.docs.where((d) => d.data()['status'] == HelpStatus.completed.name).length;
      final active = requests.docs.where((d) => d.data()['status'] == HelpStatus.open.name).length;
      
      return {
        'totalHelped': completed,
        'totalHelpers': users.docs.length,
        'activeRequests': active,
      };
    } catch (e) {
      return {'totalHelped': 0, 'totalHelpers': 0, 'activeRequests': 0};
    }
  }
}
