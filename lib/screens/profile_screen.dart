import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'activity_history_screen.dart';
import 'settings_screen.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _appState = AppState();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  Map<String, dynamic>? _userData;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _firestoreService.currentUserId;
    if (userId != null) {
      final data = await _firestoreService.getUserData(userId);
      if (mounted) {
        setState(() {
          _userData = data;
          _profileImageUrl = data?['photoUrl'];
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e'), backgroundColor: AppTheme.secondaryColor),
        );
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) return;
    
    setState(() => _isUploadingImage = true);
    
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_photos/$userId.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      
      // Update Firestore
      await _firestoreService.updateUserPhoto(url);
      
      setState(() {
        _profileImageUrl = url;
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Foto profil berhasil diperbarui'), backgroundColor: AppTheme.accentColor, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: $e'), backgroundColor: AppTheme.secondaryColor),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Pilih Foto Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(Icons.camera_alt, 'Kamera', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _buildImageOption(Icons.photo_library, 'Galeri', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppTheme.getTextPrimary(context), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildStatsRow(cardColor, textSecondary),
            const SizedBox(height: 24),
            _buildAchievements(cardColor, textPrimary, textSecondary),
            const SizedBox(height: 24),
            _buildMenuSection(context, cardColor, textPrimary, textSecondary, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final completionPercent = _appState.profileCompletion;
    final userName = _userData?['name'] ?? _appState.userName;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF8B85FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                child: _isUploadingImage
                    ? const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: CircularProgressIndicator(),
                      )
                    : _profileImageUrl != null
                        ? CircleAvatar(
                            radius: 45,
                            backgroundImage: NetworkImage(_profileImageUrl!),
                            backgroundColor: Colors.white,
                          )
                        : const CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person_rounded, size: 50, color: AppTheme.primaryColor),
                          ),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.camera_alt, size: 16, color: AppTheme.primaryColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Pengguna Tulongen', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kelengkapan Profil', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                  Text('${(completionPercent * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: completionPercent, backgroundColor: Colors.white.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor), minHeight: 6),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showProfileCompletionTips(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text('Lengkapi untuk verifikasi', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(_appState.helpGiven >= 10 ? 'Penolong Aktif' : 'Pemula', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileCompletionTips(BuildContext context) {
    final incompleteItems = _appState.incompleteProfileItems;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.tips_and_updates, color: AppTheme.primaryColor), const SizedBox(width: 8), const Text('Lengkapi Profil')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lengkapi data berikut untuk verifikasi akun:'),
            const SizedBox(height: 16),
            ...incompleteItems.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(Icons.circle_outlined, size: 16, color: AppTheme.secondaryColor), const SizedBox(width: 8), Text(item)]))),
            if (incompleteItems.isEmpty) Row(children: [Icon(Icons.check_circle, color: AppTheme.accentColor), const SizedBox(width: 8), const Text('Profil sudah lengkap!')]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          if (incompleteItems.isNotEmpty) ElevatedButton(onPressed: () { Navigator.pop(context); _showEditProfileSheet(context); }, child: const Text('Lengkapi')),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final nameController = TextEditingController(text: _appState.userName == 'Pengguna Baik Hati' ? '' : _appState.userName);
    final emailController = TextEditingController(text: _appState.userEmail);
    final phoneController = TextEditingController(text: _appState.userPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: BoxDecoration(color: AppTheme.getCardColor(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Edit Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.getTextPrimary(context))),
            const SizedBox(height: 24),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama', hintText: 'Masukkan nama lengkap', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 16),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', hintText: 'email@example.com', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 16),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. HP', hintText: '08xxxxxxxxxx', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _appState.updateProfile(name: nameController.text.isNotEmpty ? nameController.text : null, email: emailController.text.isNotEmpty ? emailController.text : null, phone: phoneController.text.isNotEmpty ? phoneController.text : null);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Profil berhasil diperbarui'), backgroundColor: AppTheme.accentColor, behavior: SnackBarBehavior.floating));
                },
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Color cardColor, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(child: _buildStatCard('${_appState.helpGiven}', 'Nulong', Icons.fitness_center_rounded, AppTheme.accentColor, cardColor, textSecondary, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('${_appState.helpReceived}', 'Ditulong', Icons.volunteer_activism_rounded, AppTheme.secondaryColor, cardColor, textSecondary, isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('${_appState.rating}', 'Rating', Icons.star_rounded, AppTheme.primaryColor, cardColor, textSecondary, isDark)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, Color cardColor, Color textSecondary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAchievements(Color cardColor, Color textPrimary, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final achievements = _appState.achievements;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Pencapaian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('${_appState.unlockedAchievements}/${achievements.length}', style: TextStyle(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: achievements.map((a) => _buildBadge(a, textPrimary, textSecondary, isDark)).toList()),
        ],
      ),
    );
  }

  Widget _buildBadge(Achievement achievement, Color textPrimary, Color textSecondary, bool isDark) {
    return GestureDetector(
      onTap: () => _showAchievementDetail(achievement),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: achievement.isUnlocked ? AppTheme.primaryColor.withValues(alpha: 0.12) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
              shape: BoxShape.circle,
              border: achievement.isUnlocked ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5) : null,
            ),
            child: Icon(achievement.icon, size: 20, color: achievement.isUnlocked ? AppTheme.primaryColor : textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.name,
            style: TextStyle(fontSize: 10, color: achievement.isUnlocked ? textPrimary : textSecondary, fontWeight: achievement.isUnlocked ? FontWeight.w600 : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetail(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: achievement.isUnlocked ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100, shape: BoxShape.circle), child: Icon(achievement.icon, size: 48, color: achievement.isUnlocked ? AppTheme.primaryColor : Colors.grey)),
            const SizedBox(height: 16),
            Text(achievement.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(achievement.description, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            if (!achievement.isUnlocked) ...[
              LinearProgressIndicator(value: achievement.progress, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
              const SizedBox(height: 8),
              Text('${(achievement.progress * 100).toInt()}% selesai', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ] else
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: AppTheme.accentColor), const SizedBox(width: 8), const Text('Tercapai!', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w600))]),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, Color cardColor, Color textPrimary, Color textSecondary, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.history_rounded, 'Riwayat Aktivitas', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryScreen())), textPrimary, textSecondary),
          _buildDivider(isDark),
          _buildMenuItem(Icons.settings_rounded, 'Pengaturan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), textPrimary, textSecondary),
          _buildDivider(isDark),
          _buildMenuItem(Icons.help_outline_rounded, 'Bantuan', () => _showHelpDialog(context), textPrimary, textSecondary),
          _buildDivider(isDark),
          _buildMenuItem(Icons.info_outline_rounded, 'Tentang Aplikasi', () => _showAboutDialog(context), textPrimary, textSecondary),
          _buildDivider(isDark),
          _buildMenuItem(Icons.logout_rounded, 'Keluar', () => _showLogoutDialog(context), textPrimary, textSecondary, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, Color textPrimary, Color textSecondary, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? AppTheme.secondaryColor : AppTheme.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: isDestructive ? AppTheme.secondaryColor : AppTheme.primaryColor),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, color: isDestructive ? AppTheme.secondaryColor : textPrimary, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) => Divider(height: 1, indent: 56, endIndent: 16, color: isDark ? Colors.white12 : Colors.grey.shade100);

  void _showHelpDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Pusat Bantuan'), content: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: const Text('help@tulongen.id')), ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Telepon'), subtitle: const Text('021-12345678')), ListTile(leading: const Icon(Icons.chat_outlined), title: const Text('Live Chat'), subtitle: const Text('Tersedia 24/7'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))]));
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), content: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.handshake, size: 48, color: AppTheme.primaryColor)), const SizedBox(height: 16), const Text('TULONGEN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Versi 1.0.0', style: TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 16), const Text('Platform untuk saling membantu sesama. Dibuat untuk Gen Z Indonesia.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))]));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar?'),
        content: const Text('Yakin mau keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              await _appState.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const OnboardingScreen()), (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
