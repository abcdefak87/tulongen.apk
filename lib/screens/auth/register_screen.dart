import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/app_state.dart';
import '../../services/auth_service.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Membuat akun...',
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    _buildProgressIndicator(context),
                    const SizedBox(height: 32),
                    _buildCurrentStepForm(context),
                    const SizedBox(height: 32),
                    _buildNavigationButtons(context),
                    const SizedBox(height: 24),
                    _buildLoginLink(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Buat Akun Baru', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 8),
        Text('Bergabung dengan komunitas penolong', style: TextStyle(fontSize: 16, color: textSecondary)),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepForm(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(context);
      case 1:
        return _buildStep2(context);
      case 2:
        return _buildStep3(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(context, 'Data Diri', 'Langkah 1 dari 3'),
        const SizedBox(height: 24),
        _buildTextField(
          context,
          controller: _nameController,
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap',
          icon: Icons.person_outline,
          validator: (v) => (v?.isEmpty ?? true) ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context,
          controller: _phoneController,
          label: 'Nomor HP',
          hint: '08xxxxxxxxxx',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'No. HP wajib diisi';
            if (v!.length < 10) return 'No. HP tidak valid';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(context, 'Akun', 'Langkah 2 dari 3'),
        const SizedBox(height: 24),
        _buildTextField(
          context,
          controller: _emailController,
          label: 'Email',
          hint: 'contoh@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Email wajib diisi';
            if (!v!.contains('@')) return 'Email tidak valid';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context,
          controller: _passwordController,
          label: 'Password',
          hint: 'Minimal 8 karakter',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Password wajib diisi';
            if (v!.length < 8) return 'Password minimal 8 karakter';
            return null;
          },
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.getTextSecondary(context)),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context,
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password',
          hint: 'Ulangi password',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Konfirmasi password wajib diisi';
            if (v != _passwordController.text) return 'Password tidak sama';
            return null;
          },
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.getTextSecondary(context)),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildPasswordStrength(context),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(context, 'Konfirmasi', 'Langkah 3 dari 3'),
        const SizedBox(height: 24),
        _buildSummaryCard(context),
        const SizedBox(height: 24),
        _buildTermsCheckbox(context),
      ],
    );
  }

  Widget _buildStepTitle(BuildContext context, String title, String subtitle) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getStepIcon(), color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 13, color: textSecondary)),
          ],
        ),
      ],
    );
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case 0: return Icons.person_outline;
      case 1: return Icons.lock_outline;
      case 2: return Icons.check_circle_outline;
      default: return Icons.circle;
    }
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
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

  Widget _buildPasswordStrength(BuildContext context) {
    final password = _passwordController.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color color;
    String label;
    switch (strength) {
      case 0:
      case 1:
        color = AppTheme.secondaryColor;
        label = 'Lemah';
        break;
      case 2:
        color = const Color(0xFFFF9F43);
        label = 'Sedang';
        break;
      case 3:
        color = AppTheme.primaryColor;
        label = 'Kuat';
        break;
      default:
        color = AppTheme.accentColor;
        label = 'Sangat Kuat';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < strength ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text('Kekuatan password: $label', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildSummaryRow(context, Icons.person_outline, 'Nama', _nameController.text),
          Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
          _buildSummaryRow(context, Icons.phone_outlined, 'No. HP', _phoneController.text),
          Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
          _buildSummaryRow(context, Icons.email_outlined, 'Email', _emailController.text),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, IconData icon, String label, String value) {
    final textSecondary = AppTheme.getTextSecondary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
            Text(value.isNotEmpty ? value : '-', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    final cardColor = AppTheme.getCardColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _agreeToTerms ? AppTheme.accentColor.withValues(alpha: 0.1) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _agreeToTerms ? AppTheme.accentColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _agreeToTerms,
            onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
            activeColor: AppTheme.accentColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textSecondary, fontSize: 13),
                children: [
                  const TextSpan(text: 'Saya setuju dengan '),
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    recognizer: TapGestureRecognizer()..onTap = () => _showTermsDialog(),
                  ),
                  const TextSpan(text: ' dan '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    recognizer: TapGestureRecognizer()..onTap = () => _showPrivacyDialog(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
              ),
              child: const Text('Kembali'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: _currentStep > 0 ? 2 : 1,
          child: ElevatedButton(
            onPressed: _handleNext,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _currentStep == 2 ? AppTheme.accentColor : AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _currentStep == 2 ? 'Daftar Sekarang' : 'Lanjut',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    final textSecondary = AppTheme.getTextSecondary(context);
    
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Sudah punya akun? ', style: TextStyle(color: textSecondary)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text('Masuk', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        _showErrorSnackbar('Mohon lengkapi semua data');
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep++);
    } else {
      _handleRegister();
    }
  }

  final _appState = AppState();
  final _authService = AuthService();

  void _handleRegister() async {
    if (!_agreeToTerms) {
      _showErrorSnackbar('Kamu harus menyetujui Syarat & Ketentuan');
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _authService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );
    
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      // Save login state with user data
      await _appState.login(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );
      
      if (!mounted) return;
      
      // Show verification dialog
      if (result.needsVerification) {
        _showVerificationDialog();
      } else {
        _showSuccessDialog();
      }
    } else {
      _showErrorSnackbar(result.error ?? 'Gagal membuat akun');
    }
  }

  void _showVerificationDialog() {
    final cardColor = AppTheme.getCardColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.mark_email_read_rounded, size: 56, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text('Verifikasi Email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            Text(
              'Link verifikasi telah dikirim ke:\n${_emailController.text}',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppTheme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cek folder spam jika tidak ada di inbox',
                      style: TextStyle(fontSize: 12, color: AppTheme.accentColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Check if verified
                  final verified = await _authService.checkEmailVerified();
                  if (!mounted) return;
                  
                  if (verified) {
                    Navigator.pop(dialogContext);
                    _showSuccessDialog();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Email belum diverifikasi. Cek inbox kamu.'),
                        backgroundColor: AppTheme.secondaryColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sudah Verifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final result = await _authService.resendVerificationEmail();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.success ? 'Email verifikasi dikirim ulang' : 'Gagal mengirim email'),
                    backgroundColor: result.success ? AppTheme.accentColor : AppTheme.secondaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Kirim Ulang Email', style: TextStyle(color: AppTheme.primaryColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                );
              },
              child: Text('Lanjut Tanpa Verifikasi', style: TextStyle(color: textSecondary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    final cardColor = AppTheme.getCardColor(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.celebration, size: 56, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 24),
            Text('Selamat!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            Text(
              'Akun kamu berhasil dibuat.\nSelamat bergabung di komunitas TULONGEN!',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Mulai Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.secondaryColor, behavior: SnackBarBehavior.floating),
    );
  }

  void _showTermsDialog() {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Syarat & Ketentuan', style: TextStyle(color: textPrimary)),
        content: SingleChildScrollView(
          child: Text(
            '1. Pengguna wajib memberikan informasi yang benar.\n\n'
            '2. Pengguna bertanggung jawab atas aktivitasnya.\n\n'
            '3. Dilarang melakukan penipuan atau tindakan merugikan.\n\n'
            '4. TULONGEN berhak menonaktifkan akun yang melanggar.\n\n'
            '5. Transaksi dilakukan atas kesepakatan kedua belah pihak.',
            style: TextStyle(color: textSecondary, height: 1.5),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  void _showPrivacyDialog() {
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Kebijakan Privasi', style: TextStyle(color: textPrimary)),
        content: SingleChildScrollView(
          child: Text(
            '1. Data pribadi kamu aman bersama kami.\n\n'
            '2. Kami tidak menjual data ke pihak ketiga.\n\n'
            '3. Lokasi hanya digunakan untuk fitur terdekat.\n\n'
            '4. Kamu bisa menghapus akun kapan saja.\n\n'
            '5. Kami menggunakan enkripsi untuk keamanan data.',
            style: TextStyle(color: textSecondary, height: 1.5),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }
}
