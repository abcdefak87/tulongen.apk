import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/request_help_screen.dart';
import 'screens/offer_help_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/notifications_screen.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize app state from SharedPreferences
  await AppState().init();
  
  // Initialize push notifications
  await NotificationService().init();
  
  // Set status bar style - dark icons for light background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const TulongenApp());
}

class TulongenApp extends StatefulWidget {
  const TulongenApp({super.key});

  @override
  State<TulongenApp> createState() => _TulongenAppState();
}

class _TulongenAppState extends State<TulongenApp> {
  final _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _appState.isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _appState.isDarkMode ? AppTheme.darkCardColor : Colors.white,
        systemNavigationBarIconBrightness: _appState.isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TULONGEN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _appState.themeMode,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _appState = AppState();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    
    _controller.forward();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Check if user is already logged in
        if (_appState.isLoggedIn) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF8B85FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_rounded, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'TULONGEN',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final _appState = AppState();
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;
  late AnimationController _fabController;
  StreamSubscription? _unreadMessagesSubscription;
  StreamSubscription? _unreadNotificationsSubscription;

  final List<Widget> _screens = const [
    HomeScreen(),
    RequestHelpScreen(),
    OfferHelpScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _setupUnreadListeners();
  }

  final _notificationService = NotificationService();
  Set<String> _knownOfferIds = {};
  Set<String> _knownMessageIds = {};

  void _setupUnreadListeners() {
    final currentUserId = _firestoreService.currentUserId;
    if (currentUserId == null) return;

    // Listen for unread messages
    _unreadMessagesSubscription = _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) {
      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lastSenderId = data['lastSenderId'] ?? '';
        final lastMessage = data['lastMessage'] ?? '';
        final lastSenderName = data['lastSenderName'] ?? 'Seseorang';
        final chatId = doc.id;
        
        if (lastSenderId.isNotEmpty && lastSenderId != currentUserId) {
          unreadCount++;
          
          // Show push notification for new messages
          if (!_knownMessageIds.contains(chatId)) {
            _knownMessageIds.add(chatId);
            if (_knownMessageIds.length > 1) { // Skip first load
              _notificationService.showMessageNotification(lastSenderName, lastMessage);
            }
          }
        }
      }
      _appState.setUnreadMessages(unreadCount);
    });

    // Listen for unread notifications (offers on my requests)
    _unreadNotificationsSubscription = _db
        .collection('offers')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
      // Get my request IDs
      final myRequests = await _db
          .collection('requests')
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'open')
          .get();
      
      final myRequestIds = myRequests.docs.map((d) => d.id).toSet();
      final myRequestTitles = <String, String>{};
      for (final doc in myRequests.docs) {
        myRequestTitles[doc.id] = (doc.data())['title'] ?? 'Permintaan';
      }
      
      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final requestId = data['requestId'] ?? '';
        final offerId = doc.id;
        
        if (myRequestIds.contains(requestId)) {
          unreadCount++;
          
          // Show push notification for new offers
          if (!_knownOfferIds.contains(offerId)) {
            _knownOfferIds.add(offerId);
            if (_knownOfferIds.length > 1) { // Skip first load
              final helperName = data['helperName'] ?? 'Seseorang';
              final requestTitle = myRequestTitles[requestId] ?? 'Permintaan';
              _notificationService.showOfferNotification(helperName, requestTitle);
            }
          }
        }
      }
      _appState.setUnreadNotifications(unreadCount);
    });
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    _fabController.dispose();
    _unreadMessagesSubscription?.cancel();
    _unreadNotificationsSubscription?.cancel();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.getBackgroundColor(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Beranda'),
              _buildNavItem(1, Icons.edit_note_rounded, Icons.edit_note_outlined, 'Minta'),
              _buildCenterNavItem(),
              _buildNavItem(3, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Pesan', badge: _appState.unreadMessages),
              _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, {int badge = 0}) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 3) _appState.markMessagesAsRead();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 10,
                vertical: isSelected ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                backgroundColor: AppTheme.secondaryColor,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    key: ValueKey(isSelected),
                    color: isSelected ? AppTheme.primaryColor : unselectedColor,
                    size: isSelected ? 24 : 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : unselectedColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    final isSelected = _currentIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              'Bantu',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
