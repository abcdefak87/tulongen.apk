import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: Icons.handshake_rounded,
      title: 'Selamat Datang di\nTULONGEN',
      color: AppTheme.primaryColor,
    ),
    OnboardingData(
      icon: Icons.location_on_rounded,
      title: 'Temukan Bantuan\nTerdekat',
      color: AppTheme.accentColor,
    ),
    OnboardingData(
      icon: Icons.payments_rounded,
      title: 'Ongkos Fleksibel\n& Transparan',
      color: AppTheme.secondaryColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text('Lewati', style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index], textPrimary, textSecondary),
              ),
            ),
            // Indicators & buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildIndicators(isDark),
                  const SizedBox(height: 32),
                  _buildButtons(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [data.color.withValues(alpha: 0.25), data.color.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: data.color.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 8),
                  ],
                  border: Border.all(color: data.color.withValues(alpha: 0.15), width: 2),
                ),
                child: Icon(data.icon, size: 80, color: data.color),
              ),
            ),
          ),
          const SizedBox(height: 56),
          Text(
            data.title,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, height: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 36 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? _pages[_currentPage].color : (isDark ? Colors.white24 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(5),
            boxShadow: isActive ? [
              BoxShadow(color: _pages[_currentPage].color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
            ] : null,
          ),
        );
      }),
    );
  }

  Widget _buildButtons(bool isDark) {
    final isLastPage = _currentPage == _pages.length - 1;
    return Row(
      children: [
        if (_currentPage > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
              ),
              child: const Text('Kembali'),
            ),
          ),
        if (_currentPage > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLastPage ? _goToLogin : _nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: _pages[_currentPage].color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              shadowColor: _pages[_currentPage].color.withValues(alpha: 0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isLastPage ? 'Mulai Sekarang' : 'Lanjut', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                if (!isLastPage) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                ],
                if (isLastPage) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.rocket_launch_rounded, size: 18, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _goToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final Color color;

  OnboardingData({required this.icon, required this.title, required this.color});
}
