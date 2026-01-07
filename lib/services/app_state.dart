import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/help_request.dart';
import '../data/dummy_data.dart';

/// Global app state management using ChangeNotifier
/// Handles theme, user data, and app-wide state with persistence
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserName = 'userName';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserPhone = 'userPhone';
  static const String _keyThemeMode = 'themeMode';
  static const String _keyHelpGiven = 'helpGiven';
  static const String _keyHelpReceived = 'helpReceived';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize from SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _userName = prefs.getString(_keyUserName) ?? 'Pengguna Baik Hati';
    _userEmail = prefs.getString(_keyUserEmail) ?? '';
    _userPhone = prefs.getString(_keyUserPhone) ?? '';
    _helpGiven = prefs.getInt(_keyHelpGiven) ?? 12;
    _helpReceived = prefs.getInt(_keyHelpReceived) ?? 5;
    
    final themeModeIndex = prefs.getInt(_keyThemeMode) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    
    _isInitialized = true;
    notifyListeners();
  }

  // Theme
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, _themeMode.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  // User data
  String _userName = 'Pengguna Baik Hati';
  String _userEmail = '';
  String _userPhone = '';
  bool _isLoggedIn = false;
  
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> updateProfile({String? name, String? email, String? phone}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (name != null) {
      _userName = name;
      await prefs.setString(_keyUserName, name);
    }
    if (email != null) {
      _userEmail = email;
      await prefs.setString(_keyUserEmail, email);
    }
    if (phone != null) {
      _userPhone = phone;
      await prefs.setString(_keyUserPhone, phone);
    }
    notifyListeners();
  }

  Future<void> login({String? name, String? email, String? phone}) async {
    _isLoggedIn = true;
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (phone != null) _userPhone = phone;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    if (name != null) await prefs.setString(_keyUserName, name);
    if (email != null) await prefs.setString(_keyUserEmail, email);
    if (phone != null) await prefs.setString(_keyUserPhone, phone);
    
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = 'Pengguna Baik Hati';
    _userEmail = '';
    _userPhone = '';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhone);
    
    notifyListeners();
  }

  // Profile completion calculation
  double get profileCompletion {
    int completed = 0;
    int total = 4;
    
    if (_userName.isNotEmpty && _userName != 'Pengguna Baik Hati') completed++;
    if (_userEmail.isNotEmpty) completed++;
    if (_userPhone.isNotEmpty) completed++;
    if (_isLoggedIn) completed++;
    
    return completed / total;
  }

  List<String> get incompleteProfileItems {
    List<String> items = [];
    if (_userName.isEmpty || _userName == 'Pengguna Baik Hati') items.add('Nama lengkap');
    if (_userEmail.isEmpty) items.add('Email');
    if (_userPhone.isEmpty) items.add('Nomor HP');
    if (!_isLoggedIn) items.add('Verifikasi akun');
    return items;
  }

  // Stats - calculated from actual data
  int get totalHelped {
    return DummyData.helpRequests.where((r) => r.status == HelpStatus.completed).length;
  }

  int get totalHelpers {
    return DummyData.dummyOffers.length;
  }

  int get activeRequests {
    return DummyData.helpRequests.where((r) => r.status == HelpStatus.open).length;
  }

  // Unread messages count
  int _unreadMessages = 2;
  int get unreadMessages => _unreadMessages;

  void markMessagesAsRead() {
    _unreadMessages = 0;
    notifyListeners();
  }

  void addUnreadMessage() {
    _unreadMessages++;
    notifyListeners();
  }

  // User stats
  int _helpGiven = 12;
  int _helpReceived = 5;
  double _rating = 4.9;

  int get helpGiven => _helpGiven;
  int get helpReceived => _helpReceived;
  double get rating => _rating;

  Future<void> incrementHelpGiven() async {
    _helpGiven++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHelpGiven, _helpGiven);
    notifyListeners();
  }

  Future<void> incrementHelpReceived() async {
    _helpReceived++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHelpReceived, _helpReceived);
    notifyListeners();
  }

  // Achievements
  List<Achievement> get achievements => [
    Achievement(
      id: 'pemula',
      icon: Icons.star_outline,
      name: 'Pemula',
      description: 'Selesaikan 1 bantuan',
      isUnlocked: _helpGiven >= 1,
      progress: _helpGiven >= 1 ? 1.0 : _helpGiven / 1,
    ),
    Achievement(
      id: 'dermawan',
      icon: Icons.diamond_outlined,
      name: 'Dermawan',
      description: 'Bantu 10 orang',
      isUnlocked: _helpGiven >= 10,
      progress: _helpGiven >= 10 ? 1.0 : _helpGiven / 10,
    ),
    Achievement(
      id: 'konsisten',
      icon: Icons.local_fire_department,
      name: 'Konsisten',
      description: '7 hari berturut aktif',
      isUnlocked: false,
      progress: 0.3,
    ),
    Achievement(
      id: 'legend',
      icon: Icons.workspace_premium,
      name: 'Legend',
      description: 'Bantu 100 orang',
      isUnlocked: _helpGiven >= 100,
      progress: _helpGiven >= 100 ? 1.0 : _helpGiven / 100,
    ),
  ];

  int get unlockedAchievements => achievements.where((a) => a.isUnlocked).length;
}

class Achievement {
  final String id;
  final IconData icon;
  final String name;
  final String description;
  final bool isUnlocked;
  final double progress;

  Achievement({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    required this.isUnlocked,
    required this.progress,
  });
}
