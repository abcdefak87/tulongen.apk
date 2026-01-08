import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isEmailVerified => currentUser?.emailVerified ?? false;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);
        
        // Send email verification
        await credential.user!.sendEmailVerification();
        
        // Save user data to Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'helpGiven': 0,
          'helpReceived': 0,
          'rating': 0.0,
          'ratingCount': 0,
          'isVerified': false,
        });

        return AuthResult(success: true, user: credential.user, needsVerification: true);
      }
      return AuthResult(success: false, error: 'Gagal membuat akun');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Resend email verification
  Future<AuthResult> resendVerificationEmail() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
        return AuthResult(success: true);
      }
      return AuthResult(success: false, error: 'User tidak ditemukan');
    } catch (e) {
      return AuthResult(success: false, error: 'Gagal mengirim email verifikasi');
    }
  }

  // Check if email is verified
  Future<bool> checkEmailVerified() async {
    if (currentUser == null) return false;
    await currentUser!.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    
    if (verified) {
      // Update Firestore
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'isVerified': true,
      });
    }
    
    return verified;
  }

  // Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if email is verified
      if (credential.user != null && !credential.user!.emailVerified) {
        return AuthResult(
          success: true, 
          user: credential.user, 
          needsVerification: true,
        );
      }
      
      return AuthResult(success: true, user: credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Delete account completely
  Future<AuthResult> deleteAccount() async {
    if (currentUser == null) {
      return AuthResult(success: false, error: 'User tidak ditemukan');
    }
    
    try {
      final userId = currentUser!.uid;
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete user's requests
      final requests = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in requests.docs) {
        await doc.reference.delete();
      }
      
      // Delete user's offers
      final offers = await _firestore
          .collection('offers')
          .where('helperId', isEqualTo: userId)
          .get();
      for (var doc in offers.docs) {
        await doc.reference.delete();
      }
      
      // Delete Firebase Auth account
      await currentUser!.delete();
      
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult(success: false, error: 'Silakan login ulang untuk menghapus akun');
      }
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: 'Gagal menghapus akun: $e');
    }
  }

  // Re-authenticate user (needed before delete)
  Future<AuthResult> reauthenticate(String password) async {
    if (currentUser == null || currentUser!.email == null) {
      return AuthResult(success: false, error: 'User tidak ditemukan');
    }
    
    try {
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      await currentUser!.reauthenticateWithCredential(credential);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data();
  }

  // Update user profile
  Future<bool> updateProfile({String? name, String? phone}) async {
    if (currentUser == null) return false;
    try {
      final updates = <String, dynamic>{};
      if (name != null) {
        updates['name'] = name;
        await currentUser!.updateDisplayName(name);
      }
      if (phone != null) updates['phone'] = phone;
      
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(currentUser!.uid).update(updates);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah (min 6 karakter)';
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-credential':
        return 'Email atau password salah';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      case 'requires-recent-login':
        return 'Silakan login ulang untuk melanjutkan';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final bool needsVerification;

  AuthResult({
    required this.success, 
    this.user, 
    this.error,
    this.needsVerification = false,
  });
}
