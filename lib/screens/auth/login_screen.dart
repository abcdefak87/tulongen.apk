import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/app_state.dart';
import 'register_screen.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _appState = AppState();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.getBackgroundColor(context);
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Sedang masuk...',
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(textPrimary, textSecondary),
                    const SizedBox(height: 40),
                    _buildLoginForm(cardColor, textPrimary, textSecondary, isDark),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                    const SizedBox(height: 24),
                    _buildDivider(textSecondary, isDark),
                    const SizedBox(height: 24),
                    _buildSocialLogin(cardColor, textPrimary, isDark),
                    const SizedBox(height: 32),
                    _buildRegisterLink(textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor.withValues(alpha: 0.15), AppTheme.accentColor.withValues(alpha: 0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.handshake_rounded, size: 48, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Selamat Datang! ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
            const Text('👋', style: TextStyle(fontSize: 28)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Masuk untuk mulai saling menolong', style: TextStyle(fontSize: 16, color: textSecondary)),
      ],
    );
  }

  Widget _buildLoginForm(Color cardColor, Color textPrimary, Color textSecondary, bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email atau No. HP',
          hint: 'contoh@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Email wajib diisi';
            if (!v!.contains('@') && v.length < 10) return 'Format tidak valid';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          validator: (v) => (v?.isEmpty ?? true) ? 'Password wajib diisi' : null,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: textSecondary),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showForgotPasswordSheet(),
            child: Text('Lupa Password?', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, color: Colors.white),
            SizedBox(width: 8),
            Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(Color textSecondary, bool isDark) {
    return Row(
      children: [
        Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('atau masuk dengan', style: TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildSocialLogin(Color cardColor, Color textPrimary, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildSocialButton(icon: Icons.g_mobiledata, label: 'Google', color: const Color(0xFFDB4437), cardColor: cardColor, textPrimary: textPrimary, isDark: isDark)),
        const SizedBox(width: 16),
        Expanded(child: _buildSocialButton(icon: Icons.facebook, label: 'Facebook', color: const Color(0xFF4267B2), cardColor: cardColor, textPrimary: textPrimary, isDark: isDark)),
      ],
    );
  }

  Widget _buildSocialButton({required IconData icon, required String label, required Color color, required Color cardColor, required Color textPrimary, required bool isDark}) {
    return OutlinedButton.icon(
      onPressed: () => _showComingSoonSnackbar(),
      icon: Icon(icon, color: color, size: 24),
      label: Text(label, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade200),
        backgroundColor: cardColor,
      ),
    );
  }

  Widget _buildRegisterLink(Color textSecondary) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Belum punya akun? ', style: TextStyle(color: textSecondary)),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: Text('Daftar Sekarang', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    
    // Update app state with persistence
    await _appState.login(email: _emailController.text);
    
    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  void _showForgotPasswordSheet() {
    final emailController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('Lupa Password?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text('Masukkan email untuk reset password', style: TextStyle(color: textSecondary)),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Email kamu',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Link reset password telah dikirim ke email'), backgroundColor: AppTheme.accentColor, behavior: SnackBarBehavior.floating),
                  );
                },
                child: const Text('Kirim Link Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Fitur ini coming soon! 🚀'), backgroundColor: AppTheme.primaryColor, behavior: SnackBarBehavior.floating),
    );
  }
}
