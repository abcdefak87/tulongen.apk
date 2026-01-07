import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../main.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _appState = AppState();
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _language = 'Indonesia';
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.getBackgroundColor(context);
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Pengaturan', style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Notifikasi', textPrimary),
          _buildSettingsCard(cardColor, [
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi Push',
              subtitle: 'Terima notifikasi permintaan baru',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Privasi & Lokasi', textPrimary),
          _buildSettingsCard(cardColor, [
            _buildSwitchTile(
              icon: Icons.location_on_outlined,
              title: 'Akses Lokasi',
              subtitle: 'Izinkan akses lokasi untuk fitur terdekat',
              value: _locationEnabled,
              onChanged: (v) => setState(() => _locationEnabled = v),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Tampilan', textPrimary),
          _buildSettingsCard(cardColor, [
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Mode Gelap',
              subtitle: isDark ? 'Tema gelap aktif' : 'Aktifkan tema gelap',
              value: _appState.isDarkMode,
              onChanged: (v) {
                _appState.toggleTheme();
              },
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
            _buildDropdownTile(
              icon: Icons.language_outlined,
              title: 'Bahasa',
              value: _language,
              options: ['Indonesia', 'English'],
              onChanged: (v) {
                setState(() => _language = v!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(v == 'English' ? 'Language changed to English' : 'Bahasa diubah ke Indonesia'),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              textPrimary: textPrimary,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Akun', textPrimary),
          _buildSettingsCard(cardColor, [
            _buildActionTile(
              icon: Icons.lock_outline,
              title: 'Ubah Password',
              onTap: () => _showChangePasswordDialog(),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
            _buildActionTile(
              icon: Icons.delete_outline,
              title: 'Hapus Akun',
              isDestructive: true,
              onTap: () => _showDeleteAccountDialog(),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ]),
          const SizedBox(height: 24),
          // App info
          Center(
            child: Column(
              children: [
                Text('TULONGEN v1.0.0', style: TextStyle(color: textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Made for Gen Z Indonesia', style: TextStyle(color: textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildSettingsCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required Color textPrimary,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textPrimary)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textSecondary,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.secondaryColor : AppTheme.primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? AppTheme.secondaryColor : textPrimary)),
      trailing: Icon(Icons.chevron_right, color: textSecondary),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ubah Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (_newPasswordController.text != _confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password baru tidak cocok'),
                    backgroundColor: AppTheme.secondaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (_newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password minimal 6 karakter'),
                    backgroundColor: AppTheme.secondaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Password berhasil diubah'),
                  backgroundColor: AppTheme.accentColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Akun?'),
        content: const Text('Semua data kamu akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _appState.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Akun berhasil dihapus'),
                    backgroundColor: AppTheme.secondaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
