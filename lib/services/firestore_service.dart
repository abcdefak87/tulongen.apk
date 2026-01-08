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
    if (currentUserId == null) return null;
    
    try {
      final userData = await getUserData(currentUserId!);
      final doc = await _db.collection('requests').add({
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
      });
      return doc.id;
    } catch (e) {
      return null;
    }
  }

  // Get all open help requests (for home screen)
  Stream<List<HelpRequest>> getOpenRequests() {
    return _db
        .collection('requests')
        .where('status', isEqualTo: HelpStatus.open.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _docToHelpRequest(doc)).toList());
  }

  // Get requests by category
  Stream<List<HelpRequest>> getRequestsByCategory(HelpCategory category) {
    return _db
        .collection('requests')
        .where('status', isEqualTo: HelpStatus.open.name)
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _docToHelpRequest(doc)).toList());
  }

  // Get my requests (yang saya buat)
  Stream<List<HelpRequest>> getMyRequests() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('requests')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _docToHelpRequest(doc)).toList());
  }

  // Get requests I'm helping
  Stream<List<HelpRequest>> getMyHelping() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('requests')
        .where('helperId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _docToHelpRequest(doc)).toList());
  }

  // Update request status
  Future<bool> updateRequestStatus(String requestId, HelpStatus status, {String? helperId}) async {
    try {
      final updates = <String, dynamic>{'status': status.name};
      if (helperId != null) updates['helperId'] = helperId;
      await _db.collection('requests').doc(requestId).update(updates);
      return true;
    } catch (e) {
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

  // ============ OFFERS ============

  Future<String?> createOffer({
    required String requestId,
    required String message,
    int? offeredPrice,
  }) async {
    if (currentUserId == null) return null;
    try {
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
      return doc.id;
    } catch (e) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getOffersForRequest(String requestId) {
    return _db
        .collection('offers')
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  Future<bool> acceptOffer(String offerId, String requestId, String helperId) async {
    try {
      await _db.collection('offers').doc(offerId).update({'status': 'accepted'});
      await _db.collection('requests').doc(requestId).update({
        'status': HelpStatus.inProgress.name,
        'helperId': helperId,
      });
      return true;
    } catch (e) {
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
